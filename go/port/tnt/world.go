package tnt

import (
	"log"
	"time"
)

type State struct{
	GTime  float64 `msgpack:"gtime"`
	Stage  string `msgpack:"stage"`
	Paused bool `msgpack:"paused"`
}

type World struct{
	tnt *Conn
	heatbeat time.Duration
	State
}

func NewWorld(tnt *Conn, heartbeat int) *World{
	world := &World{
		tnt:   tnt,
		heatbeat: time.Millisecond*time.Duration(heartbeat),
	}
	go world.monitor()
	return world
}

func (w *World) Call(fname string, args... interface{}) error{
	_, err:= w.tnt.Call(fname, args...)
	return err
}

type LuaT = map[interface{}]interface{}
type JST = map[string]interface{}

func convertM(t LuaT) JST{
	res:=make(JST)
	for k,v:= range t{
		if str,ok:=k.(string); ok{
			if subT, ok:=v.(LuaT); ok{
				res[str] = convertM(subT)
			} else if subA, ok:=v.([]interface{}); ok{
				res[str] = convertA(subA)
			} else {
				res[str] = v
			}
		}
	}
	return res
}
func convertA(t []interface{}) []interface{}{
	for i, v:=range t{
		if arr, ok:=v.([]interface{}); ok{
			t[i] = convertA(arr)
		}
		if mp, ok:=v.(LuaT); ok{
			t[i] = convertM(mp)
		}
	}
	return t
}

func (w *World) CallT(fname string, args... interface{}) (JST, error){
	resp, err:= w.tnt.Call(fname, args...)
	if err!=nil{
		return nil, err
	}
	if len(resp.Data)==0 {
		return nil, nil
	}
	if resp.Data[0] == nil{
		return nil, nil
	}
	if data, ok := resp.Data[0].(LuaT); ok{
		return convertM(data), nil
	}
	if data, ok := resp.Data[0].([]interface{}); ok{
		return JST{"items": convertA(data)}, nil
	}
	return JST{"item": resp.Data[0]}, nil
}

type Stat struct{
	TNTAlive bool
}

func (w *World) Stat() Stat{
	return Stat{
		TNTAlive: w.tnt.IsAlive(),
	}
}

func (w *World) monitor(){
	const worldFName = "app.world.heartbeat"
	var st []State
	for {
		time.Sleep(w.heatbeat)
		err:=w.tnt.CallTyped(worldFName, &st)
		if err!=nil{
//			log.Println("World Monitor: ", err)
			continue
		}
		if len(st)!=1{
			log.Println("World Monitor: got weird result len", len(st))
			continue
		}
		w.State = st[0]
	}
}