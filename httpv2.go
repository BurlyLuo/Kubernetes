package main
import (
    "fmt"
    "golang.org/x/net/http2"
    "net/http"

    "net"
    "time"
)

//net/http包默认可以采用http2进行服务，在没有进行https的服务上开启H2，
//需要修改ListenAndServer的默认h2服务

type serverHandler struct {
}

func (sh *serverHandler) ServeHTTP(w http.ResponseWriter, req *http.Request) {
    fmt.Println(req)
    w.Header().Set("server", "h2test")
    w.Write([]byte("this is a http2 test sever"))
}

func main() {
    server := &http.Server{
        Addr:         ":8080",
        Handler:      &serverHandler{},
        ReadTimeout:  5 * time.Second,
        WriteTimeout: 5 * time.Second,
    }
    //http2.Server.ServeConn()
    s2 := &http2.Server{
        IdleTimeout: 1 * time.Minute,
    }
    http2.ConfigureServer(server, s2)
    l, _ := net.Listen("tcp", ":8080")
    defer l.Close()
    fmt.Println("Start server...")
    for {
        rwc, err := l.Accept()
        if err != nil {
            fmt.Println("accept err:", err)
            continue
        }
        go s2.ServeConn(rwc, &http2.ServeConnOpts{BaseConfig: server})

    }
    //http.ListenAndServe(":8888",&serverHandler{})
}
