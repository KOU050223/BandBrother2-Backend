package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

func wsHandler(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Upgrade error:", err)
		return
	}
	defer conn.Close()

	for {
		mt, message, err := conn.ReadMessage()
		if err != nil {
			log.Println("Read error:", err)
			break
		}
		log.Printf("Received: %s", message)
		reply := fmt.Sprintf("Hello, %s", message)
		err = conn.WriteMessage(mt, []byte(reply))
		if err != nil {
			log.Println("Write error:", err)
			break
		}
	}
}

func helloWorldHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprint(w, "helloworld")
}

func main() {
	http.HandleFunc("/ws", wsHandler)
	http.HandleFunc("/", helloWorldHandler)
	log.Println("WebSocket server started on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
