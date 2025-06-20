package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"sync"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

// メッセージ構造体
type Message struct {
	Type       string `json:"type"`
	RoomId     string `json:"roomId,omitempty"`
	Difficulty string `json:"difficulty,omitempty"`
	Score      int    `json:"score,omitempty"`
	FinalScore int    `json:"finalScore,omitempty"`
	PlayerId   string `json:"playerId,omitempty"`
}

// プレイヤー情報
type Player struct {
	Conn       *websocket.Conn
	PlayerId   string
	Difficulty string
	Score      int
}

// ルーム情報
type Room struct {
	RoomId         string
	Players        map[string]*Player
	GameStarted    bool
	GameEnded      bool
	EndedPlayers   map[string]bool
	mu             sync.RWMutex
}

// グローバルなルーム管理
var rooms = make(map[string]*Room)
var roomsMutex sync.RWMutex

// Rails APIのベースURL
var railsAPIURL = func() string {
	if url := os.Getenv("RAILS_API_URL"); url != "" {
		return url + "/api"
	}
	return "http://web:3000/api"
}()

// 対戦結果をRails APIに送信するための構造体
type BattleResultRequest struct {
	Uid    string `json:"uid"`
	RoomId int    `json:"room_id"`
	Score  int    `json:"score"`
	IsWin  bool   `json:"is_win"`
}

func wsHandler(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Upgrade error:", err)
		return
	}
	defer func() {
		cleanupConnection(conn)
		conn.Close()
	}()

	for {
		var msg Message
		err := conn.ReadJSON(&msg)
		if err != nil {
			log.Println("Read error:", err)
			break
		}

		handleMessage(conn, &msg)
	}
}

func handleMessage(conn *websocket.Conn, msg *Message) {
	switch msg.Type {
	case "join":
		handleJoin(conn, msg)
	case "score_update":
		handleScoreUpdate(conn, msg)
	case "game_end":
		handleGameEnd(conn, msg)
	default:
		log.Printf("Unknown message type: %s", msg.Type)
	}
}

func handleJoin(conn *websocket.Conn, msg *Message) {
	roomsMutex.Lock()
	defer roomsMutex.Unlock()

	room, exists := rooms[msg.RoomId]
	if !exists {
		room = &Room{
			RoomId:       msg.RoomId,
			Players:      make(map[string]*Player),
			EndedPlayers: make(map[string]bool),
		}
		rooms[msg.RoomId] = room
	}

	room.mu.Lock()
	defer room.mu.Unlock()

	// プレイヤーを追加
	player := &Player{
		Conn:       conn,
		PlayerId:   msg.PlayerId,
		Difficulty: msg.Difficulty,
		Score:      0,
	}
	room.Players[msg.PlayerId] = player

	log.Printf("Player %s joined room %s with difficulty %s", msg.PlayerId, msg.RoomId, msg.Difficulty)

	// ルームの状態を他のプレイヤーに通知
	broadcastRoomStatus(room)

	// 2人揃ったらゲーム開始
	if len(room.Players) == 2 && !room.GameStarted {
		room.GameStarted = true
		startGame(room)
	}
}

func handleScoreUpdate(conn *websocket.Conn, msg *Message) {
	roomsMutex.RLock()
	room, exists := rooms[msg.RoomId]
	roomsMutex.RUnlock()

	if !exists {
		return
	}

	room.mu.Lock()
	defer room.mu.Unlock()

	if player, ok := room.Players[msg.PlayerId]; ok {
		player.Score = msg.Score
		broadcastScores(room)
	}
}

func handleGameEnd(conn *websocket.Conn, msg *Message) {
	roomsMutex.RLock()
	room, exists := rooms[msg.RoomId]
	roomsMutex.RUnlock()

	if !exists {
		return
	}

	room.mu.Lock()
	defer room.mu.Unlock()

	// ゲームが既に終了している場合は処理しない
	if room.GameEnded {
		return
	}

	if player, ok := room.Players[msg.PlayerId]; ok {
		player.Score = msg.FinalScore
		room.EndedPlayers[msg.PlayerId] = true
	}

	// 全プレイヤーが終了したら結果を送信（1回だけ）
	if len(room.EndedPlayers) == len(room.Players) && len(room.Players) == 2 {
		room.GameEnded = true
		broadcastGameResult(room)
		// ルームを削除
		roomsMutex.Lock()
		delete(rooms, msg.RoomId)
		roomsMutex.Unlock()
	}
}

func broadcastRoomStatus(room *Room) {
	statusMsg := map[string]interface{}{
		"type":        "room_status",
		"roomId":      room.RoomId,
		"playerCount": len(room.Players),
		"gameStarted": room.GameStarted,
	}

	for _, player := range room.Players {
		player.Conn.WriteJSON(statusMsg)
	}
}

func startGame(room *Room) {
	startMsg := map[string]interface{}{
		"type":   "game_start",
		"roomId": room.RoomId,
	}

	for _, player := range room.Players {
		player.Conn.WriteJSON(startMsg)
	}
	log.Printf("Game started in room %s", room.RoomId)
}

func broadcastScores(room *Room) {
	scores := make(map[string]int)
	for playerId, player := range room.Players {
		scores[playerId] = player.Score
	}

	scoreMsg := map[string]interface{}{
		"type":   "score_broadcast",
		"roomId": room.RoomId,
		"scores": scores,
	}

	for _, player := range room.Players {
		player.Conn.WriteJSON(scoreMsg)
	}
}

func broadcastGameResult(room *Room) {
	var winner string
	maxScore := -1
	tie := false

	// 勝者を決定
	for playerId, player := range room.Players {
		if player.Score > maxScore {
			maxScore = player.Score
			winner = playerId
			tie = false
		} else if player.Score == maxScore {
			tie = true
		}
	}

	resultMsg := map[string]interface{}{
		"type":   "game_result",
		"roomId": room.RoomId,
		"winner": winner,
		"tie":    tie,
		"scores": make(map[string]int),
	}

	scores := resultMsg["scores"].(map[string]int)
	for playerId, player := range room.Players {
		scores[playerId] = player.Score
	}

	for _, player := range room.Players {
		player.Conn.WriteJSON(resultMsg)
	}
	log.Printf("Game result sent for room %s. Winner: %s, Tie: %v", room.RoomId, winner, tie)

	// 対戦結果をRails APIに保存
	go saveBattleResults(room, winner, tie)
}

// 対戦結果をRails APIに保存
func saveBattleResults(room *Room, winner string, tie bool) {
	// room.RoomIdを文字列から整数に変換
	roomIdInt, err := strconv.Atoi(room.RoomId)
	if err != nil {
		log.Printf("Error converting room ID to integer: %v", err)
		return
	}

	for playerId, player := range room.Players {
		isWin := false
		if !tie && playerId == winner {
			isWin = true
		}

		// スコアが負の場合は0にする
		score := player.Score
		if score < 0 {
			score = 0
		}

		result := BattleResultRequest{
			Uid:    playerId,
			RoomId: roomIdInt,
			Score:  score,
			IsWin:  isWin,
		}

		jsonData, err := json.Marshal(result)
		if err != nil {
			log.Printf("Error marshaling battle result for player %s: %v", playerId, err)
			continue
		}

		resp, err := http.Post(railsAPIURL+"/scores", "application/json", bytes.NewBuffer(jsonData))
		if err != nil {
			log.Printf("Error sending battle result to Rails API for player %s: %v", playerId, err)
			continue
		}
		defer resp.Body.Close()

		if resp.StatusCode == http.StatusOK {
			log.Printf("Battle result saved successfully for player %s (score: %d, win: %v)", playerId, player.Score, isWin)
		} else {
			// レスポンス内容を読み取ってログに出力
			body, _ := io.ReadAll(resp.Body)
			log.Printf("Failed to save battle result for player %s, status: %d, response: %s", playerId, resp.StatusCode, string(body))
			log.Printf("Request data: %s", string(jsonData))
		}
	}
}

// コネクション切断時のクリーンアップ
func cleanupConnection(conn *websocket.Conn) {
	roomsMutex.Lock()
	defer roomsMutex.Unlock()

	// 切断されたプレイヤーを全ルームから削除
	for roomId, room := range rooms {
		room.mu.Lock()
		var disconnectedPlayerId string
		for playerId, player := range room.Players {
			if player.Conn == conn {
				disconnectedPlayerId = playerId
				delete(room.Players, playerId)
				break
			}
		}

		if disconnectedPlayerId != "" {
			log.Printf("Player %s disconnected from room %s", disconnectedPlayerId, roomId)

			// ルームが空になったら削除
			if len(room.Players) == 0 {
				room.mu.Unlock()
				delete(rooms, roomId)
				log.Printf("Room %s deleted (empty)", roomId)
			} else {
				// 他のプレイヤーに通知
				broadcastRoomStatus(room)
				room.mu.Unlock()
			}
		} else {
			room.mu.Unlock()
		}
	}
}

func helloWorldHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprint(w, "helloworld")
}

func main() {
	port := os.Getenv("WS_PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/ws", wsHandler)
	http.HandleFunc("/", helloWorldHandler)
	log.Printf("WebSocket server started on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
