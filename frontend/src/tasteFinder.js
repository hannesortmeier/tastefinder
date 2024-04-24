let state = {
    restaurants: null,
    latitude: null,
    longitude: null,
    randomRestaurant: null,
    spinner: false,
    maxDistance: 0,
    statistics: null
};

document.getElementById("fetchRandomRestaurant").addEventListener('click', function () {
    document.querySelector("#loader").style.visibility = "visible";
    fetchRandomRestaurant().then(_ => {
        const dataDisplay = document.getElementById('data-display');
        dataDisplay.innerHTML = ''; // Clear previous data
        const dataElement = document.createElement('p');
        let rand = state.randomRestaurant;
        let text = rand.name + "<br/>"
            + rand.formattedAddress + "<br/>"
            + "Luftdistanz: " + rand.distance.toFixed(2) + " km<br/>"
            + "Rating: " + rand.rating + "/5 (" + rand.userRatingsTotal + ")<br/>";
        dataElement.innerHTML = text;
        dataDisplay.appendChild(dataElement);
        document.querySelector("#loader").style.visibility = "hidden";
    }).catch(error => {
        console.error('Error fetching data:', error);
        document.querySelector("#loader").style.visibility = "hidden";
    });
});

async function fetchRandomRestaurant() {
    state.spinner = true;
    if (state.latitude === null || state.longitude === null) {
        await getCurrentPosition();
    }
    if (state.latitude === null || state.longitude === null) {
        alert("No location could be found");
    }
    if (state.restaurants === null) {
        await fetchRestaurants();
    }
    if (state.restaurants === null) {
        alert("No restaurants could be found nearby latitude " + state.latitude + " and longitude " + state.longitude);
    }
    calculate_distance()
    calculate_weights()
    state.randomRestaurant = weighted_random();
    state.spinner = false;
}

async function getCurrentPosition() {
    const position = await new Promise((resolve, reject) => {
        navigator.geolocation.getCurrentPosition(resolve, reject);
    }).catch(error => {
        console.error(error);
    });
    state.latitude = position.coords.latitude;
    state.longitude = position.coords.longitude;
}

async function fetchRestaurants() {
    await axios.get('https://d2vtbtscle6o2bh6xp7hxhqtgu0oydeh.lambda-url.eu-central-1.on.aws/ ', {
        params: {
            latitude: state.latitude,
            longitude: state.longitude
        }
    })
        .then(response => {
            state.restaurants = filter_closed_restaurants(response.data);
        })
        .catch(error => {
            console.error(error);
        });
}

function calculate_weights() {
    state.restaurants.forEach(restaurant => {
        restaurant.weight = Math.pow(state.maxDistance - restaurant.distance, 1.5) * 100 + 1;
    })

}

function calculate_distance() {
    state.restaurants.forEach(restaurant => {
        let distance = getDistanceFromLatLonInKm(
            state.latitude,
            state.longitude,
            restaurant.geometry.location.lat,
            restaurant.geometry.location.lng
        );
        restaurant.distance = distance;
        if (distance > state.maxDistance) {
            state.maxDistance = distance;
        }
    })
}

function getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
    const radius = 6371; // Radius of the earth in km
    let dLat = degree2radius(lat2 - lat1);
    let dLon = degree2radius(lon2 - lon1);
    let a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(degree2radius(lat1)) * Math.cos(degree2radius(lat2)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2)
    ;
    let b = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    // Distance in km
    return radius * b;
}

function degree2radius(deg) {
    return deg * (Math.PI / 180)
}

function weighted_random() {
    let i;
    let weights = [state.restaurants[0].weight];
    for (let j = 1; j < state.restaurants.length; j++) {
        weights.push(state.restaurants[j].weight + weights[j - 1]);
    }
    let random = Math.random() * weights[weights.length - 1];
    for (i = 0; i < weights.length; i++)
        if (weights[i] > random)
            break;
    return state.restaurants[i];
}

function filter_closed_restaurants(restaurants) {
    return restaurants.filter(restaurant => {
        return restaurant.businessStatus === "OPERATIONAL" && restaurant.permanentlyClosed === false;
    });
}

function fetch_statistics() {
    this.calculate_distance();
    this.calculate_weights();
    let i;
    let statistics = {};
    for (i = 0; i < state.restaurants.length; i++) {
        statistics[state.restaurants[i].name] = 0;
    }
    for (i = 0; i < 100000; i++) {
        if (i % 1000 === 0) {
            console.log(i)
        }
        var rest = weighted_random();
        statistics[rest.name] = statistics[rest.name] + 1;
    }
    let array = Object.entries(statistics);
    array.sort(function (a, b) {
        return a[1] - b[1]
    })
    state.statistics = array;
    console.log(state.statistics);
    console.log(state.restaurants);
}