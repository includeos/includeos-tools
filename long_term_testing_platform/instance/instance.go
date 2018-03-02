package instance

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"martin/lotto/instanceStatus"
	"os"
	"path"
	"time"
)

// Instance defines an entry that is shown to the user
type Instance struct {
	ID           string
	LogInterval  time.Duration
	LastLog      time.Time
	Notification string
	Monitoring   bool
	Health       bool
}

func (i *Instance) SaveToDisk() error {
	// Create data dir if it does not exist
	if _, err := os.Stat("data"); os.IsNotExist(err) {
		os.Mkdir("data", 0755)
	}

	// Save instance to file
	b, err := json.Marshal(i)
	if err != nil {
		return err
	}
	filename := path.Join("data", i.ID+".json")
	if err := ioutil.WriteFile(filename, b, 0600); err != nil {
		return err
	}
	return nil
}

func (i *Instance) DeleteFromDisk() error {
	filePath := path.Join("data", i.ID+".json")
	i.badHealth()
	return os.Remove(filePath)
}

func (i *Instance) Monitor(statusHandler instanceStatus.StatusGetter) error {
	go func() {
		// Setup
		fmt.Printf("Registered monitoring for: %s\n", i.ID)
		i.Monitoring = true
		// Add 25% to the expected log frequency to avoid false positives
		intervalSeconds := i.LogInterval.Seconds()
		newIntervalMilliseconds := intervalSeconds * 1.25 * 1000
		newDuration := time.Duration(time.Duration(newIntervalMilliseconds) * time.Millisecond)
		for {
			// Check if Monitoring was stopped by DeleteFromDisk
			if !i.Monitoring {
				fmt.Printf("Exiting monitoring for %s\n", i.ID)
				return
			}
			// Set expireTime, Logs need to be newer than this time
			expireTime := time.Now().In(time.FixedZone("fixed", 0)).Add(-newDuration)
			// Get Latest log from instance through statusHandler
			var err error
			i.LastLog, err = statusHandler.GetLastLog(i.ID)
			if err != nil {
				i.badHealth()
				fmt.Printf("Error getting LastLog for %s: %v", i.ID, err)
				return
			}
			// Check if the latest log from instance is expired
			newestLog := i.LastLog.In(time.FixedZone("fixed", 0))
			if newestLog.Before(expireTime) {
				i.badHealth()
				fmt.Printf("Deadline exceeded for: %s in %s\n", i.ID, i.LogInterval.String())
				return
			}
			i.Health = true
			time.Sleep(newDuration)
		}
	}()
	return nil
}

func (i *Instance) badHealth() {
	i.Monitoring = false
	i.Health = false
}

// LoadPages Reads the configurations from disk and returns a slice of all instances
func LoadPages(statusHandler instanceStatus.StatusGetter) ([]*Instance, error) {
	var instances []*Instance
	files, _ := ioutil.ReadDir("data")
	for _, f := range files {
		filePath := path.Join("data", f.Name())
		file, _ := ioutil.ReadFile(filePath)
		x := &Instance{}
		if err := json.Unmarshal(file, &x); err != nil {
			return instances, fmt.Errorf("Error unmarshaling: %v", err)
		}
		if err := x.Monitor(statusHandler); err != nil {
			return instances, fmt.Errorf("Problem registering existing monitor for: %s", x.ID)
		}
		instances = append(instances, x)
	}
	return instances, nil
}
