package tnt

import (
	"errors"
	"log"
	"time"

	"github.com/tarantool/go-tarantool"
)

type Cfg struct{
	Addr        string
	User        string
	Pass        string
	Timeout     time.Duration
	ReconnDelay time.Duration
}

type Conn struct{
	cfg Cfg
	conn *tarantool.Connection
}

var ErrNoConn = errors.New("tnt: no connection")

func Run(cfg Cfg) *Conn {
	tnt:=&Conn{
		cfg: cfg,
	}
	go tnt.monitor()
	return tnt
}

func (t *Conn) IsAlive() bool{
	return t.conn!=nil && t.conn.ConnectedNow()
}

var noArgs = make([]interface{},0)
func (t *Conn) Call(functionName string, args... interface{}) (*tarantool.Response, error){
	conn := t.conn
	if conn==nil || !conn.ConnectedNow(){
		return nil, ErrNoConn
	}
	if args==nil{
		args = noArgs
	}
	resp, err:= conn.Call17(functionName, args)
	if terr, ok:=err.(tarantool.ClientError); ok{
		if terr.Code == tarantool.ErrConnectionClosed ||
			terr.Code == tarantool.ErrConnectionNotReady{
			err = ErrNoConn
		}
	}
	return resp, err
}
func (t *Conn) CallTyped(functionName string, result interface{}, args... interface{})  error{
	conn := t.conn
	if conn==nil || !conn.ConnectedNow(){
		return ErrNoConn
	}
	if args==nil{
		args = noArgs
	}
	err:= conn.Call17Typed(functionName, args, result)
	if terr, ok:=err.(tarantool.ClientError); ok{
		if terr.Code == tarantool.ErrConnectionClosed ||
			terr.Code == tarantool.ErrConnectionNotReady{
			err = ErrNoConn
		}
	}
	return err
}

func (t *Conn) connect() (*tarantool.Connection, error){
	return tarantool.Connect(t.cfg.Addr, tarantool.Opts{
		Timeout:       t.cfg.Timeout,
		Reconnect:     t.cfg.ReconnDelay,
		User:          t.cfg.User,
		Pass:          t.cfg.Pass,
	})
}

func (t *Conn) monitor() {
	for {
		if t.conn == nil || t.conn.ClosedNow(){
			newConn,err:=t.connect()
			if err==nil{
				log.Println("Conn Monitor: connection established")
				t.conn = newConn
			}
			if err!=nil{
				//log.Println("Conn Monitor: connection err:", err)
			}
		} else if t.conn != nil && !t.conn.ConnectedNow(){
			log.Println("Conn Monitor: lost connection")
		}
		time.Sleep(t.cfg.ReconnDelay)
	}
}