![](https://raw.github.com/snarfed/bridgy/master/static/bridgy_logo_thumb.jpg) [Bridgy Fed](https://fed.brid.gy/)
===

[Bridgy Fed](https://fed.brid.gy/) is a bridge that converts between [webmentions](http://www.webmention.org/), [ActivityPub](https://activitypub.rocks/) and [OStatus](https://en.wikipedia.org/wiki/OStatus). It connects the [IndieWeb](https://indieweb.org/) with federated social networks like [Mastodon](https://joinmastodon.org/), [Hubzilla](https://project.hubzilla.org/), and others in the [fediverse](https://en.wikipedia.org/wiki/Fediverse) that support two protocols.

Bridgy Fed is a loose extension of [Bridgy](https://brid.gy/), which is a similar bridge between the IndieWeb and social media sites. As of November 2017, it has >4k users and has successfully sent >900k webmentions for responses inside those sites.

### Details

Users use Bridgy Fed by creating an IndieWeb post (in HTML with [microformats2](http://microformats.org/wiki/microformats2)) on their own web site that replies, likes, or reposts (aka announces) a post on a federated social network. They then [send a webmention to Bridgy Fed](https://fed.brid.gy/#use) to trigger it to fetch their IndieWeb post, convert it to ActivityStreams 2 (via [granary](https://granary-demo.appspot.com/)), and deliver it to the target post's author and other recipients via ActivityPub.

Bridgy Fed handles the other direction too. If a federated social network user replies to, likes, or reposts an IndieWeb post, Bridgy Fed will accept it in their inbox, translate it into a webmention, send it to the IndieWeb post, and convert the AS2 object to HTML with microformats2 to be rendered for the webmention receiver.

This is federation, not syndication. IndieWeb posts translated to AS2 objects have both post object and actor based at the IndieWeb site's domain, with appropriate ids and URLs. If the IndieWeb site is `example.com`, the ActivityPub actor id would be `@example.com@example.com`. (This is subject to change; [more background here](https://github.com/snarfed/bridgy-fed/issues/3).)

Bridgy Fed can do all this via OStatus as well.

***

Home Page: [fed.brid.gy](https://fed.brid.gy/)

Implementation Classes (Sender and/or Receiver):

* [ ] Client
* [ ] Server
* [x] Federated Server (all of the above)

Developer(s): [Ryan Barrett](https://snarfed.org/)

Interface to other applications: network service

Publicly Accessible: [x]

Source Code repo URL(s): [github.com/snarfed/bridgy-fed](https://github.com/snarfed/bridgy-fed)

* [x] 100% open source implementation

License: Public Domain / CC0

Programming Language(s): Python


## Server

### Features

The Bridgy Fed Server:

* Accepts activity submissions _via webmention_, and updates the server's Objects per rules described below
* Delivers these submissions to the inboxes of other Servers
* Receives Activity from other servers in an inbox, and updates the server's Objects per rules described below
* Delivers Objects to Clients _via webmention_

#### Accept activity submissions and produce correct side effects

> A server handling an activity submitted by an authenticated actor _via webmention_ and handling client to server interaction side effects appropriately.

When a Client submits Activities to a Server _via webmention_, the Server...

MUST

* [na] Accepts Activity Objects
* [na] Accepts non-Activity Objects, and converts to Create Activities per 7.1.1
* [x] Removes the `bto` and `bcc` properties from Objects before storage and delivery
* [na] Ignores 'id' on submitted objects, and generates a new id instead
* [na] Responds with status code 201 Created
* [na] Response includes Location header whose value is id of new object, unless the Activity is transient
* [na] Accepts Uploaded Media in submissions
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
* [na] After receiving submission with uploaded media, the server should include the upload's new URL in the submitted object's url property
* [ ] Take care not to overload other servers with delivery submissions
* Create
  * [x] merges audience properties (to, bto, cc, bcc, audience) with the Create's 'object's audience properties
  * [x] Create's actor property is copied to be the value of .object.attributedTo
* Follow
  * [na] Adds followed object to the actor's Following Collection
* Add
  * [na] Adds object to the target Collection, unless not allowed due to requirements in 7.5
* Remove
  * [na] Remove object from the target Collection, unless not allowed due to requirements in 7.5
* Like
  * [na] Adds the object to the actor's Likes Collection.
* Block
  * [na] Prevent the blocked object from interacting with any object posted by the actor.

#### Deliver to inboxes

> A federated server delivering an activity posted by a local actor to the inbox endpoints of all recipients specified in the activity, including those on other remote federated servers.

After receiving submitted Activities in an Outbox, a Server...

MUST

* [x] Performs delivery on all Activities posted to the outbox
* [x] Utilizes `to`, `bto`, `cc`, and `bcc` to determine delivery recipients.
* [x] Provides an `id` all Activities sent to other servers, unless the activity is intentionally transient.
* [x] Dereferences delivery targets with the submitting user's credentials
* [x] Delivers to all items in recipients that are Collections or OrderedCollections
  * [ ] Applies the above, recursively if the Collection contains Collections, and limits recursion depth >= 1
* [x] Delivers activity with 'object' property if the Activity type is one of Create, Update, Delete, Like, Announce
* [na] Delivers activity with 'target' property if the Activity type is one of Add, Remove
* [x] Deduplicates final recipient list
* [ ] Does not deliver to recipients which are the same as the actor of the Activity being notified about

SHOULD

* [na] NOT deliver Block Activities to their object.

#### Accept inbox notifications from other servers

> A federated server receiving an activity to its actor's inbox, validating that the activity and any nested objects were created by their respective actors, and handling server to server side effects appropriately.

When receiving notifications in an inbox, a Server...

MUST

* [ ] Deduplicates activities returned by the inbox by comparing activity `id`s
* [x] Forwards incoming activities to the values of to, bto, cc, bcc, audience if and only if criteria in 7.1.2 are met.
* Update
  * [x] Take care to be sure that the Update is authorized to modify its object

SHOULD

* [x] Don't trust content received from a server other than the content's origin without some form of verification.
* [ ] Recurse through to, bto, cc, bcc, audience object values to determine whether/where to forward according to criteria in 7.1.2
  * [ ] Limit recursion in this process
* Update
  * [x] Completely replace its copy of the activity with the newly received value
* Follow
  * [na] Add the actor to the object user's Followers Collection.
* Add
  * [na] Add the object to the Collection specified in the target property, unless not allowed to per requirements in 7.8
* Remove
  * [na] Remove the object from the Collection specified in the target property, unless not allowed per requirements in 7.9
* Like
  * [x] Perform appropriate indication of the like being performed (See 7.10 for examples)
* Announce
  * [x] Perform appropriate indication of the announce being performed (See 7.10 for examples)
* [x] Validate the content they receive to avoid content spoofing attacks.

##### Inbox Retrieval

non-normative

* [ ] Server responds to GET request at inbox URL

MUST

* [na] inbox is an OrderedCollection

SHOULD

* [na] Server filters inbox content according to the requester's permission

#### Allow Object Retrieval

According to [section 3.2](https://w3c.github.io/activitypub/#retrieving-objects), the Server...

MAY

* [ ] Allow dereferencing Object `id`s by responding to HTTP GET requests with a representation of the Object

If the above, is true, the Server...

MUST

* [ ] Respond with the ActivityStreams object representation in response to requests that primarily Accept the media type `application/ld+json; profile="https://www.w3.org/ns/activitystreams"`

SHOULD

* [ ] - Respond with the ActivityStreams object representation in response to requests that primarily Accept the media type `application/activity+json`
* Deleted Object retrieval
  * [ ] Respond with 410 Gone status code to requests for deleted objects
  * [ ] Respond with response body that is an ActivityStreams Object of type `Tombstone`.
  * [ ] Respond with 404 status code for Object URIs that have never existed
* [ ] Respond with a 403 Forbidden status code to all requests that access Objects considered Private
* [ ] Respond to requests which do not pass authorization checks using "the appropriate HTTP error code"
* [ ] Respond with a 403 Forbidden error code to all requests to Object URIs where the existence of the object is considered private.

## Security Considerations

non-normative

* [x] Server verifies that the new content is really posted by the author indicated in Objects received in inbox and outbox ([B.1](https://w3c.github.io/activitypub/#security-verification))
* [ ] By default, implementation does not make HTTP requests to localhost when delivering Activities ([B.2](https://w3c.github.io/activitypub/#security-localhost))
* [ ] Implementation applies a whitelist of allowed URI protocols before issuing requests, e.g. for inbox delivery ([B.3](https://w3c.github.io/activitypub/#security-uri-schemes))
* [ ] Server filters incoming content both by local untrusted users and any remote users through some sort of spam filter ([B.4](https://w3c.github.io/activitypub/#security-spam))
* [x] Implementation takes care to santizie fields containing markup to prevent cross site scripting attacks ([B.5](https://w3c.github.io/activitypub/#security-sanitizing-content))

## Other Features

### Requirements not yet specified

* Discovering an actor's profile based on their URI.
  * [x] Implementation first tries HTTP content negotiation, preferring AS2. If it receives HTML, it looks for a `rel-alternate` link with an AS2 content type.

