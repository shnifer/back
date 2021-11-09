package http

import (
	"encoding/json"
	"fmt"
	"io/ioutil"

	"github.com/labstack/echo/v4"
)

func bodyObj(c echo.Context) (res interface{}, err error){
	defer c.Request().Body.Close()
	body, err:=ioutil.ReadAll(c.Request().Body)
	if err!=nil{
		return nil, err
	}
	fmt.Println("BODY = ", string(body))
	err=json.Unmarshal(body, &res)
	fmt.Println("JSON err = ", err)
	if err!=nil{
		return nil, nil
	}
	return res, nil
}
