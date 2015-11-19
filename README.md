A ruby caldav client, only implementing:

* Events fetching
* Events synch ([see](https://tools.ietf.org/html/rfc4791#section-8.2.1.3))

## Usage

#### Connect to caldav server

```client = RubyCaldav::Client.new(uri: "http://localhost:5232/PATH_TO_YOUR_CALENDAR/", user: "user" , password: "password")```

*With proxy*

```client = RubyCaldav::Client.new(uri: "http://localhost:5232/PATH_TO_YOUR_CALENDAR/", user: "user" , password: "password", proxy_uri: "http://my-proxy.com:8080")```

#### Sync process
fetch etags for a given time range:

```href_etags_hash = client.find_etags("2015-11-18", "2015-11-20")```

It returns an hash with this format :

```[{:href=>"/aaa/98baca40-4234-de45-b3e3-f88a29adf235.ics", :etag=>"\"b34f392ebea0da01e0a7f12ad2e13ac8\""}, {:href=>"/aaa/8DBBD94D-056F-451C-BAD6-83E51D5FFDAB.ics", :etag=>"\"42bbd9ef29724b77ebdc199ab80d3ba2\""}, {:href=>"/aaa/DA3E39CE-F0EE-456D-A048-58570A5F418C.ics", :etag=>"\"da519a68f08cb2dc4db2a10d10e4e376\""}]```

Href are uniq and never change for a given event. Etag change every time an event is updated.

From RFC 4791: *"In order to properly detect the changes between the server and client data, the client will need to keep a record of which calendar object resources have been created, changed, or deleted since the last synchronization operation so that it can reconcile those changes with the data on the server."*

Synchronize is simply:
* If href is missing, it means that event has been deleted
* If etag has changed, it means that the event has been updated
* If href is new, it means that an event has been created

After determine this, we can simple send a *multiget* request to fetch events:

```events = client.find_events(["/aaa/98baca40-4234-de45-b3e3-f88a29adf235.ics", "/aaa/8DBBD94D-056F-451C-BAD6-83E51D5FFDAB.ics"])```

#### Events fetching
Find a single event:

```event = client.find_event("8DBBD94D-056F-451C-BAD6-83E51D5FFDAB")```

Find all events for a given time range:

```events = client.all_events("2015-11-18", "2015-11-20")```