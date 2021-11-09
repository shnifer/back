package main

import (
	"os"
	"os/signal"
	"syscall"
	"time"

	"port/http"
	"port/tnt"
)

func main() {
	tntAddr := os.Getenv("PORT_TNT_ADDR")
	if tntAddr == ""{
		tntAddr = "127.0.0.1:3301"
	}
	cfg:=tnt.Cfg{
		Addr:        tntAddr,
		User:        "myuser",
		Pass:        "mypassword",
		Timeout:     time.Second,
		ReconnDelay: time.Second,
	}
	conn:=tnt.Run(cfg)
	world:=tnt.NewWorld(conn, 500)
	go http.Start(world)

	sigCh := make(chan os.Signal)
	signal.Notify(sigCh, syscall.SIGTERM, syscall.SIGKILL)
	<- sigCh
}