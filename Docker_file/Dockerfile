# Use the official Nginx image
FROM nginx:alpine

# Copy a custom Nginx configuration file
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the static content to Nginx's default directory
COPY index.html /usr/share/nginx/html/index.html

# Expose both ports 8080 and 80
EXPOSE 8080 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]

