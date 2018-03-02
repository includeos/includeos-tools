package instanceStatus

import (
	"time"
)

type StatusGetter interface {
	GetLastLog(string) (time.Time, error)
}
