# Kroeg

Serves ActivityPub and has bridges to OStatus.

Implementation Home Page URL: [none, as of now]

Implementation Classes (Sender and/or Receiver):

* [ ] Client
* [x] Server
* [x] Federated Server (all of the above)

Developer(s): Puck Meerburg

Interface to other applications: OStatus

Publicly Accessible: [x]

Source Code repo URL(s): https://github.com/puckipedia/kroeg

* [x] 100% open source implementation

License: MIT

Programming Language(s): C#
## Server

It's a server.

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
* [x] Removes the `bto` and `bcc` properties from Objects before storage and delivery
* [x] Ignores 'id' on submitted objects, and generates a new id instead
* [x] Responds with status code 201 Created
* [x] Response includes Location header whose value is id of new object, unless the Activity is transient
* [x] Accepts Uploaded Media in submissions
  * accepts uploadedMedia file parameter
  * accepts uploadedMedia object parameter
  * Responds with status code of 201 Created or 202 Accepted as described in 6.
  * Response contains a Location header pointing to the to-be-created object's id.
  * Appends an id property to the new object

* Update
  * [x] Server takes care to be sure that the Update is authorized to modify its object before modifying the server's stored copy

SHOULD

* [x] Server does not trust client submitted content
* [x] Validate the content they receive to avoid content spoofing attacks.
* [x] After receiving submission with uploaded media, the server should include the upload's new URL in the submitted object's url property
* [x] Take care not to overload other servers with delivery submissions
* Create
  * [x] merges audience properties (to, bto, cc, bcc, audience) with the Create's 'object's audience properties
  * [x] Create's actor property is copied to be the value of .object.attributedTo
* Follow
  * [x] Adds followed object to the actor's Following Collection
* Add
  * [x] Adds object to the target Collection, unless not allowed due to requirements in 7.5
* Remove
  * [x] Remove object from the target Collection, unless not allowed due to requirements in 7.5
* Like
  * [x] Adds the object to the actor's Likes Collection.
* Block
  * [x] Prevent the blocked object from interacting with any object posted by the actor.

#### Deliver to inboxes

> A federated server delivering an activity posted by a local actor to the inbox endpoints of all recipients specified in the activity, including those on other remote federated servers.

After receiving submitted Activities in an Outbox, a Server...

MUST

* [x] Performs delivery on all Activities posted to the outbox
* [x] Utilizes `to`, `bto`, `cc`, and `bcc` to determine delivery recipients.
* [x] Provides an `id` all Activities sent to other servers, unless the activity is intentionally transient.
* [x] Dereferences delivery targets with the submitting user's credentials
* [x] Delivers to all items in recipients that are Collections or OrderedCollections
  * [x] Applies the above, recursively if the Collection contains Collections, and limits recursion depth >= 1
* [x] Delivers activity with 'object' property if the Activity type is one of Create, Update, Delete, Follow, Add, Remove, Like, Block, Undo
* [x] Delivers activity with 'target' property if the Activity type is one of Add, Remove
* [x] Deduplicates final recipient list
* [x] Does not deliver to recipients which are the same as the actor of the Activity being notified about

SHOULD

* [x] NOT deliver Block Activities to their object.

#### Accept inbox notifications from other servers

> A federated server receiving an activity to its actor's inbox, validating that the activity and any nested objects were created by their respective actors, and handling server to server side effects appropriately.

When receiving notifications in an inbox, a Server...

MUST

* [x] Deduplicates activities returned by the inbox by comparing activity `id`s
* [x] Forwards incoming activities to the values of to, bto, cc, bcc, audience if and only if criteria in 8.1.2 are met.
* Update
  * [x] Take care to be sure that the Update is authorized to modify its object

SHOULD

* [x] Don't trust content received from a server other than the content's origin without some form of verification.
* [x] Recurse through to, bto, cc, bcc, audience object values to determine whether/where to forward according to criteria in 8.1.2
  * [x] Limit recursion in this process
* Update
  * [x] Completely replace its copy of the activity with the newly received value
* Follow
  * [x] Add the actor to the object user's Followers Collection.
* Add
  * [x] Add the object to the Collection specified in the target property, unless not allowed to per requirements in 8.6
* Remove
  * [x] Remove the object from the Collection specified in the target property, unless not allowed per requirements in 8.6
* Like
  * [x] Perform appropriate indication of the like being performed (See 8.8 for examples)
* [x] Validate the content they receive to avoid content spoofing attacks.

##### Inbox Retrieval

non-normative

* [x] Server responds to GET request at inbox URL

MUST

* [x] inbox is an OrderedCollection

SHOULD

* [x] Server filters inbox content according to the requester's permission

#### Allow Object Retrieval

According to [section 3.2](https://w3c.github.io/activitypub/#retrieving-objects), the Server...

MAY

* [x] Allow dereferencing Object `id`s by responding to HTTP GET requests with a representation of the Object

If the above, is true, the Server...

MUST

* [x] Respond with the ActivityStreams object representation in response to requests that primarily Accept the media type `application/ld+json; profile="https://www.w3.org/ns/activitystreams"`

SHOULD

* [x] - Respond with the ActivityStreams object representation in response to requests that primarily Accept the media type `application/activity+json`
* Deleted Object retrieval
  * [x] Respond with 410 Gone status code to requests for deleted objects
  * [x] Respond with response body that is an ActivityStreams Object of type `Tombstone`.
  * [x] Respond with 404 status code for Object URIs that have never existed
* [x] Respond with a 403 Forbidden status code to all requests that access Objects considered Private
* [x] Respond to requests which do not pass authorization checks using "the appropriate HTTP error code"
* [x] Respond with a 403 Forbidden error code to all requests to Object URIs where the existence of the object is considered private.

## Security Considerations

non-normative

* [x] Server verifies that the new content is really posted by the author indicated in Objects received in inbox and outbox ([B.1](https://w3c.github.io/activitypub/#security-verification))
* [ ] By default, implementation does not make HTTP requests to localhost when delivering Activities ([B.2](https://w3c.github.io/activitypub/#security-localhost))
* [x] Implementation applies a whitelist of allowed URI protocols before issuing requests, e.g. for inbox delivery ([B.3](https://w3c.github.io/activitypub/#security-uri-schemes))
* [ ] Server filters incoming content both by local untrusted users and any remote users through some sort of spam filter ([B.4](https://w3c.github.io/activitypub/#security-spam))
* [ ] Implementation takes care to santizie fields containing markup to prevent cross site scripting attacks ([B.5](https://w3c.github.io/activitypub/#security-sanitizing-content))

## Other Features

### Requirements not yet specified

* Discovering an actor's profile based on their URI.
  * TODO clarify acceptance criteria: https://github.com/w3c/activitypub/issues/173
