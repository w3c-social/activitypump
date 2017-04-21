# distbin.com activitypub implementation report

Distbin is a distributed pastebin. Anyone can anonymously create little text posts, and anyone else can reply to them.

You can even create posts that are inReplyTo parent posts that are hosted elsewhere on the web (like another distbin.com installation), and distbin will tell the parent about it via ActivityPub.

distbin is made up of at least two components:
* core - Speaks only JSON/ActivityPub
* distbin-html
  * Renders a homepage with a form that helps an end-user build Create Note activites
  * Renders created activities to HTML
  * Renders the public collection to HTML

Implementation Home Page URL: https://distbin.com

Implementation Classes (Sender and/or Receiver):

* [x] Client
* [x] Server
* [x] Federated Server (all of the above)

Developer(s): [Benjamin Goering](http://bengo.is)

Interface to other applications: network service

Publicly Accessible: [x]

Source Code repo URL(s): n/a

* [ ] 100% open source implementation

License: 

Programming Language(s): JavaScript

## Client

distbin is a client infsofar as it is a Federated Server and sends requests to other ActivityPub servers.

### Features

#### Outbox Submission

> A client receiving authorization and subsequently submitting an activity to the authenticated actor's outbox.

According to [Section 7](https://w3c.github.io/activitypub/#client-to-server-interactions)...

MUST

* [ ] Client discovers the URL of a user's outbox from their profile
* [x] Client submits activity by sending an HTTP post request to the outbox URL with the Content-Type of application/ld+json; profile="https://www.w3.org/ns/activitystreams#"
* [x] Client submission request body is either a single Activity or a single non-Activity Object
  * [ ] Clients provide the object property when submitting the following activity types to an outbox: Create, Update, Delete, Follow, Add, Remove, Like, Block, Undo.
  * [ ] Clients provide the target property when submitting the following activity types to an outbox: Add, Remove.
* [ ] Client submission request is authenticated with the credentials of the user to whom the outbox belongs
* [ ] Client supports [uploading media](https://www.w3.org/TR/activitypub/#uploading-media) by sending a multipart/form-data request body

SHOULD

* [ ] Before submitting a new activity or object, Client infers appropriate target audience by recursively looking at certain properties (e.g. `inReplyTo`, See Section 7), and adds these targets to the new submission's audience.
  * [ ] Client limits depth of this recursion.

#### Retrieving Objects

MUST

* [x] When retrieving objects, Client specifies an Accept header with the `application/ld+json; profile="https://www.w3.org/ns/activitystreams#"` media type ([3.2](https://w3c.github.io/activitypub/#retrieving-objects))

## Server

### Features

A Server:

* Accepts activity submissions in an outbox, and updates the server's Objects per rules described below
* Delivers these submissions to the inboxes of other Servers
* Receives Activity from other servers in an inbox, and updates the server's Objects per rules described below
* Makes Objects available for retrieval by Clients

#### Accept activity submissions and produce correct side effects

> A server handling an activity submitted by an authenticated actor to their outbox and handling client to server interaction side effects appropriately.

When a Client submits Activities to a Server's outbox, the Server...

MUST

* [x] Accepts Activity Objects
* [x] Accepts non-Activity Objects, and converts to Create Activities per 7.1.1
* [ ] Removes the `bto` and `bcc` properties from Objects before storage and delivery
* [x] Ignores 'id' on submitted objects, and generates a new id instead
* [x] Responds with status code 201 Created
* [x] Response includes Location header whose value is id of new object, unless the Activity is transient
* [ ] Accepts Uploaded Media in submissions
  * accepts uploadedMedia file parameter
  * accepts uploadedMedia object parameter
  * Responds with status code of 201 Created or 202 Accepted as described in 6.
  * Response contains a Location header pointing to the to-be-created object's id.
  * Appends an id property to the new object

* Update
  * [ ] Server takes care to be sure that the Update is authorized to modify its object before modifying the server's stored copy

SHOULD

* [x] Server does not trust client submitted content
* [ ] Validate the content they receive to avoid content spoofing attacks.
* [ ] After receiving submission with uploaded media, the server should include the upload's new URL in the submitted object's url property
* [ ] Take care not to overload other servers with delivery submissions
* Create
  * [ ] merges audience properties (to, bto, cc, bcc, audience) with the Create object's audience properties
  * [ ] Create's actor property is copied to be the value of .object.attributedTo
* Follow
  * [ ] Adds followed object to the actor's Following Collection
* Add
  * [ ] Adds object to the target Collection, unless not allowed due to requirements in 7.5
* Remove
  * [ ] Remove object from the target Collection, unless not allowed due to requirements in 7.5
* Like
  * [ ] Adds the object to the actor's Likes Collection.
* Block
  * Prevent the blocked object from interacting with any object posted by the actor.

#### Deliver to inboxes

> A federated server delivering an activity posted by a local actor to the inbox endpoints of all recipients specified in the activity, including those on other remote federated servers.

After receiving submitted Activities in an Outbox, a Server...

MUST

* [x] Performs delivery on all Activities posted to the outbox
* [x] Utilizes `to`, `bto`, `cc`, and `bcc` to determine delivery recipients.
* [x] Provides an `id` all Activities sent to other servers, unless the activity is intentionally transient.
* [ ] Dereferences delivery targets with the submitting user's credentials
* [ ] Delivers to all items in recipients that are Collections or OrderedCollections
  * [ ] Applies the above, recursively if the Collection contains Collections, and limits recursion depth >= 1
* [ ] Delivers activity with 'object' property if the Activity type is one of Create, Update, Delete, Follow, Add, Remove, Like, Block, Undo
* [ ] Delivers activity with 'target' property if the Activity type is one of Add, Remove
* [x] Deduplicates final recipient list
* [ ] Does not deliver to recipients which are the same as the actor of the Activity being notified about

SHOULD

* [ ] NOT deliver Block Activities to their object.

#### Accept inbox notifications from other servers

> A federated server receiving an activity to its actor's inbox, validating that the activity and any nested objects were created by their respective actors, and handling server to server side effects appropriately.

When receiving notifications in an inbox, a Server...

MUST

* [x] Deduplicates activities returned by the inbox by comparing activity `id`s
* [] Forwards incoming activities to the values of to, bto, cc, bcc, audience if and only if criteria in 8.1.2 are met.
* Update
  * [ ] Take care to be sure that the Update is authorized to modify its object

SHOULD

* [ ] Don't trust content received from a server other than the content's origin without some form of verification.
* [ ] Recurse through to, bto, cc, bcc, audience object values to determine whether/where to forward according to criteria in 8.1.2
  * [ ] Limit recursion in this process
* Update
  * [ ] Completely replace its copy of the activity with the newly received value
* Follow
  * [ ] Add the actor to the object user's Followers Collection.
* Add
  * [ ] Add the object to the Collection specified in the target property, unless not allowed to per requirements in 8.6
* Remove
  * [ ] Remove the object from the Collection specified in the target property, unless not allowed per requirements in 8.6
* Like
  * [ ] Perform appropriate indication of the like being performed (See 8.8 for examples)
* [ ] Validate the content they receive to avoid content spoofing attacks.

##### Inbox Retrieval

non-normative

* [x] Server responds to GET request at inbox URL

MUST

* [x] inbox is an OrderedCollection

SHOULD

* [ ] Server filters inbox content according to the requester's permission

#### Allow Object Retrieval

According to [section 3.2](https://w3c.github.io/activitypub/#retrieving-objects), the Server...

MAY

* [x] Allow dereferencing Object `id`s by responding to HTTP GET requests with a representation of the Object

If the above, is true, the Server...

MUST

* [x] Respond with the ActivityStreams object representation in response to requests that primarily Accept the media type `application/ld+json; profile="https://www.w3.org/ns/activitystreams#"`

SHOULD

* [x] - Respond with the ActivityStreams object representation in response to requests that primarily Accept the media type `application/activity+json`
* Deleted Object retrieval
  * [ ] Respond with 410 Gone status code to requests for deleted objects
  * [ ] Respond with response body that is an ActivityStreams Object of type `Tombstone`.
  * [ ] Respond with 404 status code for Object URIs that have never existed
* [ ] Respond with a 403 Forbidden status code to all requests that access Objects considered Private
* [ ] Respond to requests which do not pass authorization checks using "the appropriate HTTP error code"
* [ ] Respond with a 403 Forbidden error code to all requests to Object URIs where the existence of the object is considered private.

## Security Considerations

non-normative

* [ ] Server verifies that the new content is really posted by the author indicated in Objects received in inbox and outbox ([B.1](https://w3c.github.io/activitypub/#security-verification))
* [ ] By default, implementation does not make HTTP requests to localhost when delivering Activities ([B.2](https://w3c.github.io/activitypub/#security-localhost))
* [ ] Implementation applies a whitelist of allowed URI protocols before issuing requests, e.g. for inbox delivery ([B.3](https://w3c.github.io/activitypub/#security-uri-schemes))
* [ ] Server filters incoming content both by local untrusted users and any remote users through some sort of spam filter ([B.4](https://w3c.github.io/activitypub/#security-spam))
* [x] Implementation takes care to santizie fields containing markup to prevent cross site scripting attacks ([B.5](https://w3c.github.io/activitypub/#security-sanitizing-content))

## Other Features

### Requirements not yet specified

* Discovering an actor's profile based on their URI.
  * TODO clarify acceptance criteria: https://github.com/w3c/activitypub/issues/173
