package server

import (
	"fmt"
	"html/template"
	"log"
	"martin/lotto/instance"
	"martin/lotto/instanceStatus"
	"net/http"
	"path"
	"time"
)

var instances []*instance.Instance
var statusHandler instanceStatus.StatusGetter

func addHandler(w http.ResponseWriter, r *http.Request) {
	addTemplate := path.Join("templates", "add.html")
	t, _ := template.ParseFiles(addTemplate)
	i := &instance.Instance{}
	t.Execute(w, i)
}

func mainHandler(w http.ResponseWriter, r *http.Request) {
	//updateLastLog()
	viewTemplate := path.Join("templates", "view.html")
	t, _ := template.ParseFiles(viewTemplate)
	//fmt.Printf("%+v\n", instances)
	t.Execute(w, instances)
}

func saveHandler(w http.ResponseWriter, r *http.Request) {
	id := r.FormValue("Id")
	notification := r.FormValue("Notification")
	logInterval, err := time.ParseDuration(r.FormValue("LogInterval"))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	inst := &instance.Instance{ID: id, LogInterval: logInterval, Notification: notification}
	if err := inst.Monitor(statusHandler); err != nil {
		fmt.Println("Problem registering monitor for: ", inst.ID)
	}
	if err := inst.SaveToDisk(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
	instances = append(instances, inst)
	http.Redirect(w, r, "/", http.StatusFound)
}

func deleteHandler(w http.ResponseWriter, r *http.Request) {
	toDelete := r.URL.Path[len("/delete/"):]
	for index, v := range instances {
		if v.ID == toDelete {
			if err := v.DeleteFromDisk(); err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
			}
			instances = append(instances[:index], instances[index+1:]...)
		}
	}
	http.Redirect(w, r, "/", http.StatusFound)
}

/*
func updateLastLog() {
	var err error
	for i, instance := range instances {
		var lastLog time.Time
		lastLog, err = statusHandler.GetLastLog(instance.Id)
		if err != nil {
			instances[i].LastLog = time.Time{}
			fmt.Printf("Error when getting lastlog: %v", err)
		}
		instances[i].LastLog = lastLog
	}
}
*/

func Serve(handler instanceStatus.StatusGetter, instanceSlice []*instance.Instance) {
	statusHandler = handler
	instances = instanceSlice
	http.HandleFunc("/", mainHandler)
	http.HandleFunc("/add/", addHandler)
	http.HandleFunc("/save/", saveHandler)
	http.HandleFunc("/delete/", deleteHandler)
	log.Fatal(http.ListenAndServe(":8080", nil))
}
