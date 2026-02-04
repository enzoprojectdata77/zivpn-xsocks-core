package log

import (
	"fmt"
	"sync"
)

type LogHandler interface {
	WriteLog(message string)
}

var (
	handlerMu sync.RWMutex
	logHandler LogHandler
)

func SetHandler(h LogHandler) {
	handlerMu.Lock()
	logHandler = h
	handlerMu.Unlock()
}

func emit(level Level, template string, args ...any) {
	handlerMu.RLock()
	h := logHandler
	handlerMu.RUnlock()

	if h != nil {
		msg := fmt.Sprintf(template, args...)
		h.WriteLog(fmt.Sprintf("[%s] %s", level.String(), msg))
	}
}
