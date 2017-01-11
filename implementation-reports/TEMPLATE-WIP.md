This file is a sample implementation report. Fork this repository, copy this file to a new `.md` file and change the name to your project name (in lower case with hyphens between words), and fill out the information in the report based on your implementation. When you are finished, submit a <a href="https://help.github.com/articles/using-pull-requests/">pull request</a> and your report will be reviewed and added to the main repository.

Complete this report by filling out the checkboxes as appropriate. To mark one as successful/complete/true, add an `x` between the brackets, e.g. `[x]`. If the statement does not apply to your implementation, use `[na]` and add a sentence explaining why it does not apply.

If your implementation is only a Client or only a Server, and not both (a Federated Server), remove the inapplicable sections from the document before submitting.

When you are complete, send a pull request with the addition of your report file. Please remove this entire top section before submitting. If you haven't already, also consider filing an [ActivityStreams implemention report](https://github.com/w3c/activitystreams/blob/master/implementation-reports/template.md).

# Implementation Name (Replace this header)

Summary of the project.
Summary of the role ActivityPub plays in enabling the project's goals and the goals of its end-users.

Implementation Home Page URL: 

Implementation Classes (Sender and/or Receiver): 
* [ ] Client
* [ ] Server
* [ ] Federated Server (all of the above)

Developer(s): [Name](http://you.example.com)

Interface to other applications: library | network service | other
Publicly Accessible: [ ]

Source Code repo URL(s): 
* [ ] 100% open source implementation
License: 
Programming Language(s): 

## Client

Description of software component that acts as an ActivityPub Client, and how an end-user makes use of it.

### Features

#### Activity Submission


> A client receiving authorization and subsequently submitting an activity to the authenticated actor's outbox.
- Section 7, Client to Server Interaction

"To submit new Activities to a user's server, "
* [ ] - "clients MUST discover the URL of the user's outbox from their profile"

"and then "

* [ ] - clients "MUST make an HTTP POST request to to this URL with the Content-Type of application/ld+json; profile="https://www.w3.org/ns/activitystreams#""
* [ ] - "The request MUST be authenticated with the credentials of the user to whom the outbox belongs. The body of the POST request must contain a single Activity (which may contain embedded objects), or a single non-Activity object which will be wrapped in a Create activity by the server.

* [ ] - Client supports uploading media. "To accomplish this, a client MUST submit a multipart/form-data message to the user's uploadMedia endpoint on their ActivityStreams profile object." (Sec. 6)


#### Object Retrieval

* [ ] - When retrieving objects, "The client MUST specify an Accept header with the application/ld+json; profile="https://www.w3.org/ns/activitystreams#" media type in order to retrieve the activity."

## Server

Description of software component that acts as an ActivityPub Server, and how an end-user makes use of it.

### Features

#### Accept activity submissions and produces side effects

> A server handling an activity submitted by an authenticated actor to their outbox and handling client to server interaction side effects appropriately.

#### Deliver activities to inboxes of recipients

> A federated server delivering an activity posted by a local actor to the inbox endpoints of all recipients specified in the activity, including those on other remote federated servers.

MUST

* [ ] - MUST - [3.1](https://www.w3.org/TR/activitypub/#obj-id) - "Identifiers MUST be provided for activities posted in server to server communication, unless the activity is intentionally transient."

#### Accept notifications from other servers

> A federated server receiving an activity to its actor's inbox, validating that the activity and any nested objects were created by their respective actors, and handling server to server side effects appropriately.

## Security Considerations (B)

* [ ] acceptance criteria (NORMATIVITY)

## Other Features

### Exit Criteria Features

* Discovering an actor's profile based on their URI.
  * TODO clarify acceptance criteria: https://github.com/w3c/activitypub/issues/173

### Non-Exit-Criteria Features implied by the spec

#### Object Retrieval


##### Server

> The HTTP GET method may be dereferenced against an object's id property to retrieve the activity.

Spec uses lowercase 'may', but in the details there is a MUST.

* [ ] - MAY? - "The HTTP GET method may be dereferenced against an object's id property to retrieve the activity."
  * [ ] - MUST - presents the ActivityStreams object representation in response to application/ld+json; profile="https://www.w3.org/ns/activitystreams#"
  * [ ] - SHOULD - presents the ActivityStreams representation in response to application/activity+json as wel

