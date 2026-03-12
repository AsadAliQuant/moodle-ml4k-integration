# ML4K × Moodle Integration

> A Moodle Activity Plugin that integrates [Machine Learning for Kids (ML4K)](https://machinelearningforkids.co.uk/) directly into Moodle LMS — enabling teachers and students to create, train, and test machine learning models without ever leaving Moodle.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Database Schema](#database-schema)
- [API Reference](#api-reference)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Reporting & Logs](#reporting--logs)
- [Security](#security)
- [Contributing](#contributing)

---

## Overview

This project integrates a cloned version of the open-source ML4K platform with Moodle LMS via a custom REST API. Teachers can create machine learning activities inside Moodle, and students can build, train, and test ML models (text classification via IBM Watson) — all from within the Moodle environment.

**Key Goals:**
- Eliminate the need for students to navigate to an external ML4K platform
- Allow teachers to manage and monitor ML activities directly in Moodle
- Support model deployment via Scratch 3 and Python
- Provide detailed activity logs and reports for both teachers and students

---

## Architecture

The integration follows a multi-component pipeline:

```
Moodle Plugin  →  REST API  →  Redis Queue  →  Celery Worker  →  Webhook  →  Moodle Plugin DB
```

| Component | Role |
|---|---|
| **Moodle LMS** | Hosts the custom activity plugin; UI for teachers and students |
| **REST API** | Intermediary between Moodle and the ML4K clone |
| **ML4K Clone** | Provides ML functionalities (IBM Watson for text projects) |
| **Redis** | High-performance message broker and cache |
| **Celery Worker** | Asynchronous task queue for long-running ML tasks (training, prediction) |
| **Flower GUI** | Web dashboard for monitoring Celery workers |
| **Webhook** | Receives completed task results from Celery and pushes them to the Plugin DB |

**Data Flow:**
1. Moodle Plugin sends a request (e.g., train model) to the API
2. API queues the task in Redis and returns an acknowledgement to Moodle
3. A Celery Worker picks up the task and processes it against the ML4K clone
4. On completion, the Worker fires an HTTP POST to the Webhook
5. The Webhook stores results in the Moodle Plugin Database
6. The Moodle Activity Page reads and displays the updated data

---

## Tech Stack

- **LMS:** Moodle (PHP)
- **API:** Python (REST)
- **ML Backend:** ML4K Clone + IBM Watson API (text classification)
- **Queue:** Redis + Celery
- **Monitoring:** Flower GUI
- **Database:** PostgreSQL (ML4K), MySQL (Moodle Plugin DB)
- **Storage:** IBM Cloud Object Storage (training data)

---

## Database Schema

The Moodle Plugin database contains the following tables:

| Table | Description |
|---|---|
| `users` | Stores Moodle student/teacher credentials |
| `projects` | ML projects linked to users (type, name, URL) |
| `labels` | Classification labels per project |
| `examples` | Training examples per project |
| `training` | Timestamps of training sessions per project |
| `predictions` | Input/output pairs from prediction calls |
| `scratch` | Scratch 3 project URLs linked to ML projects |
| `python` | Python instructions and generated code per project |
| `studentActivity` | Per-student activity metrics (access times, model/training/test counts) |
| `studentModels` | Individual models created by students |

The full schema SQL file is located at [`database/schema.sql`](database/schema.sql).

---

## API Reference

All endpoints are prefixed with `/api`. Authentication uses session tokens obtained via login.

### Authentication
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/auth/login` | Authenticate a Moodle user in the ML4K service |
| POST | `/api/auth/logout` | Log out a Moodle user |

### User Management
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/users/create` | Create a new user account in the ML4K clone |

**Payload:** `{ username, email, password }`

### Project Management
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/project/{projectType}` | Create a new ML project |
| GET | `/api/project/{projectType}` | Get all project IDs for a user |
| DELETE | `/api/project/{projectType}` | Delete a project |

### Labels Management
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/project/{projectType}/label` | Create a new label |
| GET | `/api/project/{projectType}/label` | Retrieve all labels for a project |
| DELETE | `/api/project/{projectType}/label` | Delete a label |

### Examples Management
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/project/{projectType}/example` | Add a training example |
| GET | `/api/project/{projectType}/example` | Retrieve all labels and their examples |
| DELETE | `/api/project/{projectType}/example` | Delete an example |

### Model Training & Prediction
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/project/{projectType}/train` | Trigger asynchronous model training |
| POST | `/api/project/{projectType}/predict` | Make a prediction using a trained model |

### Make (Scratch / Python)
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/project/{projectType}/make/scratch` | Generate a Scratch 3 project from trained model |
| GET | `/api/project/{projectType}/make/scratch` | Retrieve Scratch project details |
| POST | `/api/project/{projectType}/make/python` | Generate Python code from trained model |
| GET | `/api/project/{projectType}/make/python` | Retrieve Python project details |

> `{projectType}` refers to the type of ML model, e.g., `text`.

---

## Getting Started

### Prerequisites

- Moodle instance (v3.x or higher)
- Python 3.9+
- Redis server
- IBM Cloud account (Watson NLU API key for text projects)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/ml4k-moodle-integration.git
   cd ml4k-moodle-integration
   ```

2. **Install Python dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Fill in IBM Watson credentials, Redis URL, Moodle webhook URL, DB connection strings
   ```

4. **Set up the database**
   ```bash
   mysql -u root -p moodle_plugin_db < database/schema.sql
   ```

5. **Start Redis and Celery**
   ```bash
   redis-server
   celery -A app.celery worker --loglevel=info
   ```

6. **Start the API server**
   ```bash
   python app.py
   ```

7. **Install the Moodle Plugin**
   - Copy the plugin folder into your Moodle `/mod` directory
   - Visit `Site Administration > Notifications` to complete installation

8. **(Optional) Start Flower monitoring dashboard**
   ```bash
   celery -A app.celery flower
   # Visit http://localhost:5555
   ```

---

## Project Structure

```
ml4k-moodle-integration/
├── api/                  # REST API (Python)
│   ├── routes/           # Endpoint definitions
│   ├── tasks/            # Celery task definitions
│   └── webhook/          # Webhook handler
├── moodle-plugin/        # Moodle Activity Plugin (PHP)
│   ├── db/               # Plugin DB install/upgrade scripts
│   └── view.php          # Activity view page
├── database/
│   └── schema.sql        # Moodle Plugin DB schema
├── docs/                 # Project documentation & mockups
├── .env.example
├── requirements.txt
└── README.md
```

---

## Reporting & Logs

### Teacher View
- List of students who accessed the activity with first/last access timestamps
- Number of models created per student
- Model details: name, type, creation date
- Training and testing session counts

### Student View
- Personal activity summary (models created, training sessions, tests run)
- First and last access timestamps
- Full list of their own models with details

---

## Security

- HTTPS enforced for all API communication
- Secure token-based authentication
- Input validation and robust error handling on all endpoints
- Rate limiting to prevent abuse
- Passwords stored with hashing

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "Add your feature"`
4. Push to your branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
