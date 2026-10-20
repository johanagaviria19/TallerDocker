package com.ecoair.backend.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

@Entity
@Table(name = "alerts")
public class Alert {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String sensorId;
    private String location;
    private Double pollutionLevel;
    private String alertType;
    private LocalDateTime timestamp;
    private String status;

    public Alert() {}

    public Alert(String sensorId, String location, Double pollutionLevel,
                 String alertType, LocalDateTime timestamp, String status) {
        this.sensorId = sensorId;
        this.location = location;
        this.pollutionLevel = pollutionLevel;
        this.alertType = alertType;
        this.timestamp = timestamp;
        this.status = status;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getSensorId() { return sensorId; }
    public void setSensorId(String sensorId) { this.sensorId = sensorId; }

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }

    public Double getPollutionLevel() { return pollutionLevel; }
    public void setPollutionLevel(Double pollutionLevel) { this.pollutionLevel = pollutionLevel; }

    public String getAlertType() { return alertType; }
    public void setAlertType(String alertType) { this.alertType = alertType; }

    public LocalDateTime getTimestamp() { return timestamp; }
    public void setTimestamp(LocalDateTime timestamp) { this.timestamp = timestamp; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
