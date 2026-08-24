# Cloud-Ready-Ops

This repository contains the architecture, configurations, and deployment steps for a three-tier infrastructure implemented on Google Cloud Platform (GCP).

**Web Server Public IP:** `http://34.4.111.71`

## 1. Network and Security Configuration

A **custom VPC** was created, which functions as a private and isolated virtual network that allows internal communication between all components of the architecture. Two subnets were defined within this VPC:
- **Public Subnet:** Hosts resources and servers that require direct exposure to the Internet. This network uses the `10.0.1.0/24` CIDR block.
- **Private Subnet:** Encapsulates and isolates the database to prevent it from being exposed to the external network, ensuring that it only responds to requests from the internal network. This network uses the `10.0.2.0/24` CIDR block.

### 2. Firewall Rules (Security Groups)

Firewall rules were created to restrict inbound traffic to the servers, allowing access to specific ports from specified IP addresses. This adds an additional layer of security by controlling who can access the servers.
Parameters for each rule:

| **Rule Name** | **Destination Subnet** | **Protocol / Port** | **Allowed Source** | **Purpose**                                 |
| ------------- | ---------------------- | ------------------- | ------------------ | ------------------------------------------- |
| `web`         | public subnet          | TCP / 80            | `0.0.0.0/0`        | Public web traffic to Nginx                 |
| `ssh-google`  | public / private       | TCP / 22            | `35.235.240.0/20`  | Remote SSH connection                       |
| `base-datos`  | private subnet         | TCP / 3306          | `10.0.1.0/24`      | Allow the web server to access the database |
| `ssh-compu`   | public subnet          | TCP / 22            | `---`              | Remote SSH connection from my computer      |

## 3. Web Server Creation

**Provisioning:** A Compute Engine instance (Ubuntu) was created in the `10.0.1.0/24` subnet with a public IP address assigned to provide Internet access. The corresponding SSH keys were also added to allow connection to the console.

**Web Service Installation:** The server was accessed remotely via SSH, and Nginx was installed as the web server.

```
sudo apt update
sudo apt install nginx
```

**Service Verification:** The service was tested by accessing the public IP address from a web browser. After confirming that Nginx was working correctly by displaying the default Nginx welcome page, the `index.html` website was deployed to the `/var/www/html/` directory.

# 4. Database Server Creation

**Provisioning and Connectivity:** A Compute Engine instance (Ubuntu) was created in the `10.0.2.0/24` subnet without a public IP address, meaning it does not have direct Internet connectivity. To enable package downloads from the Internet within the private subnet without exposing the database, **Cloud Router** and **Cloud NAT** were configured in GCP.

**Database Engine Installation and Configuration:** The server was accessed remotely via SSH, and MariaDB was installed as the database engine.

```
sudo apt install mariadb-server
```

The secure installation was then executed, and the root password was configured. The MariaDB configuration file `/etc/mysql/mysql.conf.d/mysqld.cnf` was also modified so that MariaDB listens for requests from any server `0.0.0.0`. Since the firewall rules already restrict traffic, this does not compromise the security of the database.

The service was restarted to apply the new configuration:

```
sudo systemctl restart mysql
```

Finally, a new user was created with full privileges, which will be used specifically to connect from the web server and create the database.

```
CREATE USER 'Admin'@'%' IDENTIFIED BY 'ClaveSegura123!';
GRANT ALL PRIVILEGES ON *.* TO 'appuser'@'%';
FLUSH PRIVILEGES;
```

**Data Structure and User Creation:** From the web server, `mariadb-client` was installed to connect to the database.

```
sudo apt update
sudo apt install mariadb-client
```

The `admin` user was then used to remotely access the MariaDB console and create the database.

```
mariadb-client -h 10.0.2.5 -u admin -p
```