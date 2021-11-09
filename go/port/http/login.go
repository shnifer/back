package http

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/labstack/echo/v4"
)

type LoginResponse struct{
	Token string `json:"token"`
	Data json.RawMessage `json:"data"`
}

func (r router) login (c echo.Context) error{
	obj, err:=bodyObj(c)
	if err!=nil{
		return err
	}
	t, err:=r.w.CallT("login", obj)
	if err!=nil{
		c.String(500, err.Error())
		return err
	}
	token,ok:=t["token"].(string)
	if !ok{
		err:=errors.New("token not a string")
		c.String(500, err.Error())
		return err
	}
	c.SetCookie(&http.Cookie{
		Name:       "X-Auth-Token",
		Value:      token,
		MaxAge:     3600*24,
		HttpOnly:   true,
	})
	return c.JSON(200, t)
}