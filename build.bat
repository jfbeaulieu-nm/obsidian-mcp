@echo off
REM Build script for Obsidian MCP Docker image (Windows)

echo Building Obsidian MCP Docker image...
echo.

REM Check if Docker is running
docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not installed or not running.
    echo Please install Docker Desktop and ensure it's running.
    pause
    exit /b 1
)

REM Build the image
echo Building image: obsidian-mcp:latest
docker build -t obsidian-mcp:latest .

if errorlevel 1 (
    echo ERROR: Build failed!
    pause
    exit /b 1
)

echo.
echo SUCCESS: Image built successfully!
echo.
echo You can now configure your MCP client to use this image.
echo See DOCKER.md for configuration instructions.
echo.
pause