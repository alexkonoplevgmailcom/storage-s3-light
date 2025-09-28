#!/bin/bash

# NetApp S3 Container Management Script
# Provides commands to start, stop, restart, and check status of NetApp S3 containers

set -e

SCRIPT_DIR="$(dirname "$0")"
COMPOSE_FILE="$SCRIPT_DIR/docker/docker-compose.netapp.yml"

show_usage() {
    echo "🔱 NetApp S3 Container Management"
    echo "================================="
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start     - Start NetApp S3 containers (persistent)"
    echo "  stop      - Stop NetApp S3 containers"  
    echo "  restart   - Restart NetApp S3 containers"
    echo "  status    - Show container status"
    echo "  logs      - Show container logs"
    echo "  console   - Open NetApp S3 console in browser"
    echo "  clean     - Stop containers and remove volumes"
    echo ""
    echo "NetApp S3 Console: http://localhost:9011"
    echo "Credentials: netapp-admin / netapp-secure-password-2024"
}

start_containers() {
    echo "🚀 Starting NetApp S3 containers..."
    docker-compose -f "$COMPOSE_FILE" up -d
    
    echo "⏳ Waiting for NetApp S3 to be ready..."
    sleep 5
    
    # Check if S3 API is responding
    max_attempts=10
    attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f http://localhost:9010/minio/health/live > /dev/null 2>&1; then
            echo "✅ NetApp S3 is ready!"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            echo "❌ NetApp S3 not responding after $max_attempts attempts"
            return 1
        fi
        
        echo "   Attempt $attempt/$max_attempts..."
        sleep 2
        ((attempt++))
    done
    
    echo ""
    echo "🔱 NetApp StorageGRID S3 Simulator Started"
    echo "=========================================="
    echo "🌐 Console: http://localhost:9011"
    echo "🔗 S3 API: http://localhost:9010"
    echo "🔑 Login: netapp-admin / netapp-secure-password-2024"
    echo "📊 Default Bucket: trident-storage"
    echo ""
    echo "✅ Containers will restart automatically if stopped"
    echo "💾 Data persisted in Docker volume 'docker_netapp_s3_data'"
}

stop_containers() {
    echo "🛑 Stopping NetApp S3 containers..."
    docker-compose -f "$COMPOSE_FILE" stop
    echo "✅ NetApp S3 containers stopped"
}

restart_containers() {
    echo "🔄 Restarting NetApp S3 containers..."
    docker-compose -f "$COMPOSE_FILE" restart
    echo "✅ NetApp S3 containers restarted"
}

show_status() {
    echo "📊 NetApp S3 Container Status"
    echo "============================"
    
    if docker ps --filter "name=netapp-s3-simulator" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "netapp-s3-simulator"; then
        echo "✅ Containers Running:"
        docker ps --filter "name=netapp-s3-simulator" --filter "name=trident-simulator" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        echo ""
        echo "🔗 Access Information:"
        echo "   Console: http://localhost:9011"
        echo "   S3 API:  http://localhost:9010"
        echo "   Login:   netapp-admin / netapp-secure-password-2024"
        
        # Test API connectivity
        if curl -s -f http://localhost:9010/minio/health/live > /dev/null 2>&1; then
            echo "   Status:  🟢 S3 API responding"
        else
            echo "   Status:  🔴 S3 API not responding"
        fi
    else
        echo "❌ NetApp S3 containers not running"
        echo ""
        echo "To start: $0 start"
    fi
}

show_logs() {
    echo "📋 NetApp S3 Container Logs"
    echo "=========================="
    docker-compose -f "$COMPOSE_FILE" logs -f --tail 50
}

open_console() {
    if docker ps --filter "name=netapp-s3-simulator" --format "{{.Names}}" | grep -q "netapp-s3-simulator"; then
        echo "🌐 Opening NetApp S3 console..."
        open http://localhost:9011
        echo "✅ Console opened in browser"
        echo "🔑 Login: netapp-admin / netapp-secure-password-2024"
    else
        echo "❌ NetApp S3 containers not running"
        echo "Start containers first: $0 start"
    fi
}

clean_all() {
    echo "🧹 Cleaning up NetApp S3 containers and volumes..."
    docker-compose -f "$COMPOSE_FILE" down -v --remove-orphans
    echo "✅ All NetApp S3 data cleaned up"
}

# Main command handling
case "${1:-}" in
    start)
        start_containers
        ;;
    stop)
        stop_containers
        ;;
    restart)
        restart_containers
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    console)
        open_console
        ;;
    clean)
        clean_all
        ;;
    *)
        show_usage
        exit 1
        ;;
esac