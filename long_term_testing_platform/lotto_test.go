package main

import (
	"testing"
	"time"
)

func TestLotto(t *testing.T) {
	loadPages()
	i := &instance{"Man", time.Duration(20), "webhook"}
	if err := i.save(); err != nil {
		t.Errorf("Failed to save: %v", err)
	}
	i = &instance{"Woman", time.Duration(10), "webhook"}
	if err := i.save(); err != nil {
		t.Errorf("Failed to save: %v", err)
	}
}
