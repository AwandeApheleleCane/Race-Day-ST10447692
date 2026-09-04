# RaceDay API Endpoint Plan

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|-------------|-------|-------------|---------------|--------------|-------------------|
| POST | /api/auth/register | Creates a new user account (Participant or Organiser) | None | `{ email, password, firstName, lastName, role }` | 201 Created – user summary. 400 Validation errors. 409 Email already exists |
| POST | /api/auth/login | Authenticates user and returns JWT + refresh token | None | `{ email, password }` | 200 OK – `{ token, refreshToken, user }`. 401 Invalid credentials |
| POST | /api/auth/refresh | Issues a new access token using a valid refresh token | None | `{ refreshToken }` | 200 OK – new tokens. 401 Invalid/expired |
| GET | /api/users/me | Returns the logged-in user’s profile | Any | None | 200 OK – profile DTO |
| PUT | /api/users/me | Updates own profile (name, etc.) | Any | `{ firstName, lastName }` | 200 OK – updated profile. 400 Validation |
| GET | /api/events | Lists published events (filterable by date/province) | None / Any | None (query params optional) | 200 OK – array of EventDto |
| GET | /api/events/{id} | Returns a single event with its categories | None / Any | None | 200 OK – EventDetailDto. 404 Not found |
| POST | /api/events | Creates a new event | Organiser | `{ name, description, eventDate, location, province, maxParticipants }` | 201 Created – EventDto. 400 Validation |
| PUT | /api/events/{id} | Updates an existing event | Organiser (owner) | Event update object | 200 OK. 403 Forbidden if not owner. 404 |
| DELETE | /api/events/{id} | Soft-deletes or cancels an event | Organiser (owner) | None | 204 No Content. 403/404 |
| GET | /api/events/{eventId}/categories | Lists categories for an event | None / Any | None | 200 OK – CategoryDto[] |
| POST | /api/events/{eventId}/categories | Adds a category to an event | Organiser (owner) | `{ name, distanceKm, entryFee, maxEntries }` | 201 Created |
| PUT | /api/categories/{id} | Updates a category | Organiser | Category update | 200 OK. 403/404 |
| DELETE | /api/categories/{id} | Removes a category (if no enrolments) | Organiser | None | 204. 409 if enrolments exist |
| POST | /api/enrolments | Participant enters an event category | Participant | `{ categoryId }` | 201 Created – EnrolmentDto. 409 Already enrolled / full. 404 |
| GET | /api/enrolments/me | Lists the logged-in participant’s enrolments | Participant | None | 200 OK – EnrolmentDto[] |
| GET | /api/events/{eventId}/enrolments | Organiser views all enrolments for an event | Organiser | None | 200 OK |
| DELETE | /api/enrolments/{id} | Participant cancels own enrolment (or Organiser removes) | Participant (own) / Organiser | None | 204. 403/404 |
| POST | /api/results | Organiser records a result for an enrolment | Organiser | `{ enrolmentId, finishTime, position, status }` | 201 Created. 409 Result already exists |
| GET | /api/results/me | Participant views own results history | Participant | None | 200 OK |
| GET | /api/events/{eventId}/results | Public or Organiser view of results | None / Organiser | None | 200 OK |
| PUT | /api/results/{id} | Updates a recorded result | Organiser | Result update | 200 OK |
