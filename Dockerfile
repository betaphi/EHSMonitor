# Use the official Swift Docker image as a base
FROM swift:5.9

# Install necessary tools: Git for cloning the repository
RUN apt update && apt install -y \
    git \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory inside the container
WORKDIR /app

# Clone the GitHub repository
RUN git clone https://github.com/betaphi/EHSMonitor.git

# Change directory into the cloned repository
WORKDIR /app/EHSMonitor

# Run swift build to build the project
RUN swift build
