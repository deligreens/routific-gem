Routific Ruby Gem
=================

[![Build Status](https://secure.travis-ci.org/asoesilo/routific-gem.png)](http://travis-ci.org/asoesilo/routific-gem)

This Ruby Gem assists users to easily access the [Routific API][1], which is a practical and scalable solution to the Vehicle Routing Problem.

  [1]: https://routific.com/developers

Installing
----------

`gem install routific`

Usage
-----
Remember to require it and instantiate it with your token before using it

```ruby
require 'routific'
routific = Routific.new("INSERT API KEY")
```

You can also specify the endpoint you want to use. By default, the endpoint used is 'vrp'. The available endpoints are: 'vrp', 'vrp-long', 'pdp', 'pdp-long', 'product/projects' (as well as 'min-idle', not tested yet). Check [the official doc](https://docs.routific.com/docs/api-reference) and [the beta doc](https://docs.google.com/document/d/1_Rs624SERcou_j3IeLO1exrb5rSfUMXUkOyrvj6nTCA/edit#) for more info about each of them.

```ruby
require 'routific'
routific = Routific.new("INSERT API KEY", "INSERT ENDPOINT")
```

### Instance methods

`routific.endpoint=(value)`

Sets the default endpoint to use

`routific.setVisit( id, [params] )`

Sets a visit for the specified location using the specified parameters

Required arguments in params:

- location: Object representing the location of the visit.
  + lat: Latitude of this location
  + lng: Longitude of this location
  + name: (optional) Name of the location

Optional arguments in params:

 - start: the earliest time for this visit. Default value is 00:00, if not specified.
 - end: the latest time for this visit. Default value is    23:59, if not specified.
 - duration: the length of this visit in minutes
 - demand: the capacity that this visit requires

`routific.setVehicle( id, params )`

Sets a vehicle with the specified ID and parameters

Required arguments in params:

- start_location: Object representing the start location for this vehicle.
  + lat: Latitude of this location
  + lng: Longitude of this location
  + name: (optional) Name of the location

Optional arguments in params:

 - end_location: Object representing the end location for this vehicle.
  + lat: Latitude of this location
  + lng: Longitude of this location
  + name: (optional) Name of the location

 - shift_start: this vehicle's start shift time (e.g. '08:00'). Default value is 00:00, if not specified.
 - shift_end: this vehicle's end shift time (e.g. '17:00'). Default value is 23:59, if not specified.
 - capacity: the capacity that this vehicle can load

`routific.getRoute()`

Returns the route using the previously provided network, visits and fleet information

--> cf [Example 1](#example-1)


### Class methods

`Routific.setToken( token )`

Sets the default access token to use

`Routific.setRaiseOnException( boolean )`

Sets whether errors in the Api request and response parsing should throw exceptions or fail silently. Defaults to false.

`Routific.setLogRequests( logger )`

Sets the ruby Logger to be used to log errors, request logs etc. If no logger is explicitly set, logs are sent to STDOUT

`Routific.setLogRequests( boolean )`

Sets whether the result of requests should be logged. Defaults to false.

`Routific.endpoint=(value)`

Sets the default endpoint to use

`Routific.getRoute( [params], token = @token, endpoint = @endpoint )`

Token and endpoint are optional. Add them if you want to change them.

* If the endpoint used is "vrp" or "pdp":

Returns the route using the specified access token, network, visits and fleet information

Both getRoute functions return the Route object, which has the following attributes:

 - status: A sanity check, will always be success when the HTTP code is 200
 - fitness: Total travel-time, representing the fitness score of the solution (less is better)
 - unserved: List of visits that could not be scheduled.
 - vehicleRoutes: The optimized schedule

 --> cf [Example 2](#example-2)

* If the endpoint used is "vrp-long" or "pdp-long":

Returns a hash including the job_id needed to call the job. Call "id" on it on store the result in a variable.

--> cf [Example 3](#example-3)

Please check [Example 4](#example-4) bellow if you want to create a project on Routific Interface with "vrp-long".

`Routific.job(job_id, token = @token).route`

Returns the route for larger-routing problems (long running tasks) using the specified access job_id (to generate using the getRoute method with a "vrp-long" or "pdp-long" endpoint), token, options, visits and fleet information.

`Routific.createProject(params, token = @token)`

Create a project with the specified data information in your Routific dashboard. The endpoint used for the API call is "product/projects".

--> cf [Example 5](#example-5)


### Examples
--------
#### Example 1:

```ruby
require 'routific'

routific = Routific.new("INSERT API KEY")

routific.setVisit("order_1", {
  "start" => "9:00",
  "end" => "12:00",
  "duration" => 10,
  "location" => {
    "name" => "6800 Cambie",
    "lat" => 49.227107,
    "lng" => -123.1163085,
  }
})

routific.setVehicle("vehicle_1", {
  "start_location" => {
    "name" => "800 Kingsway",
    "lat" => 49.2553636,
    "lng" => -123.0873365,
  },
  "end_location" => {
    "name" => "800 Kingsway",
    "lat" => 49.2553636,
    "lng" => -123.0873365,
  },
  "shift_start" => "8:00",
  "shift_end" => "12:00",
})

routific.setOptions("options": {
   "traffic": "slow",
   "min_visits_per_vehicle": 5,
   "balance": true,
   "min_vehicles": true,
   "shortest_distance": true,
   "squash_durations": 1
})

route = routific.getRoute()
```

#### Example 2:

```ruby
require 'routific'

Routific.setToken("INSERT API KEY")

visits = {
  "order_1" => {
    "start" => "9:00",
    "end" => "12:00",
    "duration" => 10,
    "location" => {
      "name" => "6800 Cambie",
      "lat" => 49.227107,
      "lng" => -123.1163085
    }
  }
}

fleet = {
  "vehicle_1" => {
    "start_location" => {
      "name" => "800 Kingsway",
      "lat" => 49.2553636,
      "lng" => -123.0873365
    },
    "end_location" => {
      "name" => "800 Kingsway",
      "lat" => 49.2553636,
      "lng" => -123.0873365
    },
    "shift_start" => "8:00",
    "shift_end" => "12:00"
  }
}

options: {
   "traffic": "slow",
   "min_visits_per_vehicle": 5,
   "balance": true,
   "min_vehicles": true,
   "shortest_distance": true,
   "squash_durations": 1
}

data = {
  visits: visits,
  fleet: fleet,
  options: options
}

route = Routific.getRoute(data)
```

#### Example 3:

```ruby
require 'routific'

Routific.setToken("INSERT API KEY")

visits = {
  "order_1" => {
    "start" => "9:00",
    "end" => "12:00",
    "duration" => 10,
    "location" => {
      "name" => "6800 Cambie",
      "lat" => 49.227107,
      "lng" => -123.1163085
    }
  }
}

fleet = {
  "vehicle_1" => {
    "start_location" => {
      "name" => "800 Kingsway",
      "lat" => 49.2553636,
      "lng" => -123.0873365
    },
    "end_location" => {
      "name" => "800 Kingsway",
      "lat" => 49.2553636,
      "lng" => -123.0873365
    },
    "shift_start" => "8:00",
    "shift_end" => "12:00"
  }
}

options = {
   "traffic": "slow",
   "min_visits_per_vehicle": 5,
   "balance": true,
   "min_vehicles": true,
   "shortest_distance": true,
   "squash_durations": 1
}

data = {
  visits: visits,
  fleet: fleet,
  options: options
}

job_id = Routific.getRoute(data, "vrp-long").id
route = Routific.job(job_id).route
```

#### Example 4:

```ruby
require 'routific'

Routific.setToken("INSERT API KEY")

visits = {
  "order_1" => {
    "start" => "9:00",
    "end" => "12:00",
    "duration" => 10,
    "location" => {
      "name" => "6800 Cambie",
      "lat" => 49.227107,
      "lng" => -123.1163085
    }
  }
}

fleet = {
  "vehicle_1" => {
    "start_location" => {
      "name" => "800 Kingsway",
      "lat" => 49.2553636,
      "lng" => -123.0873365
    },
    "end_location" => {
      "name" => "800 Kingsway",
      "lat" => 49.2553636,
      "lng" => -123.0873365
    },
    "shift_start" => "8:00",
    "shift_end" => "12:00"
  }
}

options = {
   "traffic": "slow",
   "min_visits_per_vehicle": 5,
   "balance": true,
   "min_vehicles": true,
   "shortest_distance": true,
   "squash_durations": 1,
   "project": {
      "date": "2017-03-04",
      "name": "Mon projet"
  }
}

data = {
  visits: visits,
  fleet: fleet,
  options: options
}

job_id = Routific.getRoute(data, "vrp-long").id
route = Routific.job(job_id).route
```

#### Example 5:

```ruby
require 'routific'

Routific.setToken("INSERT API KEY")

settings: {
  "duration": 10,
  "traffic": "normal",
  "shortestDistance" : false,
  "strictStart" : true,
  "autoBalanced" : true,
  "distanceFormat" : "miles"
}

fleet: {
  "vehicle_1": {
    "capacity": null,
    "name": "Vehicle Name",
    "phone_number": "+15128675309", 
    "shift_start": "8:00",
    "shift_end": "16:00",
    "start_location": {
      "address": "788 Beatty Street, Vancouver, BC, Canada",
      "id": "a3024890f7614ae3f9e609b12dc18b52"
    }
  }
}

visits: {
  "Anabel": {
    "duration": 5,
    "end": "17:00",
    "location": {
      "address": "1800 Robson, Vancouver, Canada",
      "coords": {}
    },
    "name": "Anabel",
    "start": "8:00",
    "meta": {
    "customNote": "something",
    "invoiceNumber": "3212551"
  },
  "phone": "+14087448838"
  },
  "Armen": {
    "duration": 5,
    "end": "17:00",
    "location": {
      "address": "8500 Granville Street, Vancouver, Canada",
      "coords": {
        "lat": 49.2058462,
        "lng": -123.1406448
      }
    },
    "name": "Armen",
    "start": "8:00"
  },
  "Elena": {
    "duration": 15,
    "end": "17:00",
    "location": {
      "address": "8600 Knight Street, Vancouver, Canada",
      "coords": {
        "lat": 49.2121916,
        "lng": -123.0771292
      }
    },
    "name": "Elena",
    "notes": "Use backdoor",
    "start": "8:00"
  }

data = {
  "name": "Project Name",
  "date": "2016-06-27",
  "settings": settings,
  "fleet": fleet,
  "visits": visits
}

Routific.createProject(data)
```
