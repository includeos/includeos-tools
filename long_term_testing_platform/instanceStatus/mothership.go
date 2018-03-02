package instanceStatus

import (
	"bufio"
	"fmt"
	"martin/lotto/util"
	"strings"
	"time"
)

type mothership struct {
	mBin  string
	mHost string
	mUser string
	mPwd  string
}

func NewMothership(bin, host, user, pwd string) *mothership {
	ship := &mothership{}
	ship.mBin = bin
	ship.mHost = host
	ship.mUser = user
	ship.mPwd = pwd
	return ship
}

func (m *mothership) GetLastLog(instance string) (time.Time, error) {
	status, err := m.mothershipCmd("inspect-instance", instance)
	if err != nil {
		return time.Time{}, err
	}
	scanner := bufio.NewScanner(strings.NewReader(status))
	for scanner.Scan() {
		split := strings.Split(scanner.Text(), ":")
		if split[0] == "Last Log" {
			result := strings.Split(scanner.Text(), "Log:")[1]
			result = strings.TrimSpace(result)
			t, err := time.Parse("2006-01-02 15:04:05.999999999 -0700 MST", result)
			if err != nil {
				return time.Time{}, err
			}
			return t, nil
		}
	}
	return time.Time{}, fmt.Errorf("No last log for instance found")
}

func (m *mothership) mothershipCmd(cmds ...string) (string, error) {
	baseCmd := fmt.Sprintf("%s --host %s --username %s --password %s ", m.mBin, m.mHost, m.mUser, m.mPwd)
	fullCmd := baseCmd + fmt.Sprintf(strings.Join(cmds, " "))
	return util.ExternalCommand(fullCmd)
}
