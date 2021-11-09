package http

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"io/ioutil"
	"log"
	"strings"

	"port/tnt"
)

type router struct{
	w *tnt.World
}

func Start(w *tnt.World){
	e:=echo.New()
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())
	e.Use(middleware.CORS())

	r:=router{w: w}

	e.GET("/", r.healthcheck)
	e.GET("/healthcheck", r.healthcheck)

	e.GET("*", r.universal)
	e.POST("*", r.universal)
	e.DELETE("*", r.universal)

	e.Logger.Fatal(e.Start(":80"))
}

// Handler
func (r router) healthcheck (c echo.Context) error {
	return c.JSON(200, r.w.Stat())
}

type UniversalRequest struct{
	Method string `msgpack:"method"`
	Path []string `msgpack:"path"`
	Query map[string][]string `msgpack:"query"`
	Header map[string][]string `msgpack:"header"`
	PostForm map[string][]string `msgpack:"postform"`
	Body string `msgpack:"body"`
}

type ErrResp struct{
	ErrorType string `json:"error_type"`
	Message interface{} `json:"message,omitempty"`
}

func (r router) universal (c echo.Context) error {

	pathParts:=strings.Split(c.Request().URL.Path, "/")
	if len(pathParts)==0{
		return errors.New("weird path")
	}

	ur := UniversalRequest{
		Method: c.Request().Method,
		Path: pathParts[1:],
		Query: c.Request().URL.Query(),
		Header: c.Request().Header,
		PostForm: make(map[string][]string),
	}

	if strings.HasPrefix(
		c.Request().Header.Get("Content-Type"),
		"application/x-www-form-urlencoded") {
		err:=c.Request().ParseForm()
		if err!=nil{
			return err
		}
		ur.PostForm = c.Request().PostForm
		fmt.Printf("POSTFORM=%+v\n", ur.PostForm)
	} else {
		body, err:=ioutil.ReadAll(c.Request().Body)
		if err!=nil{
			return err
		}
		ur.Body = string(body)
	}

	got, err:=r.w.CallT("app.router.universal", ur)
	if err!=nil{
		return err
	}
	if got == nil{
		return c.NoContent(200)
	}

	if got["ERROR_TYPE"]!=nil{
		httpCode,ok := got["HTTP_CODE"].(uint64)
		if !ok{
			httpCode = 500
		}

		errorType, ok:=got["ERROR_TYPE"].(string)
		if !ok{
			errorType = "<broken type>"
		}

		return c.JSON(int(httpCode), ErrResp{
			ErrorType: errorType,
			Message: got["MESSAGE"],
		})
	}
	return c.JSON(200, got)
}

func viewHandler(w *tnt.World) func (echo.Context) error{
	return func (c echo.Context) error {
		fmt.Println("WIVEW HANDLER")
		viewName:=c.Param("view_name")
		headers:=c.Request().Header
		body,err :=ioutil.ReadAll(c.Request().Body)
		if err!=nil{
			log.Println("can't parse body: ", err)
			return err
		}
		var v interface{}
		err=json.Unmarshal(body, &v)
		if err!=nil{
			log.Println("unmarshal err:", err)
			return err
		}
		err=w.Call("view_handler", viewName, headers, v)
		if err!=nil {
			log.Println("world call, err:", err)
		}
		return err
	}
}