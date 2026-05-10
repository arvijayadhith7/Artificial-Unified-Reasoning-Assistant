FROM node:20

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy all source code
COPY . .

# Expose port 7860 for Hugging Face
ENV PORT=7860
EXPOSE 7860

# Start the server
CMD ["node", "server.js"]
