const api_url = 'https://ymzn5cwpkwut2xiffz7o7ur6he0aijzb.lambda-url.us-east-1.on.aws'
let input_data = {
    function: {
        name: 'get_user_data',
        params: {
            username: 'JUssing'
        }
    }
}
// Example POST method implementation:lambda
async function postData(url = '', data = {}) {
    // Default options are marked with *
    const response = await fetch(url, {
        method: 'POST', // *GET, POST, PUT, DELETE, etc.
        mode: 'cors', // no-cors, *cors, same-origin
        cache: 'no-cache', // *default, no-cache, reload, force-cache, only-if-cached
        credentials: 'same-origin', // include, *same-origin, omit
        headers: {
            'Content-Type': 'application/json'
            // 'Content-Type': 'application/x-www-form-urlencoded',
        },
        redirect: 'follow', // manual, *follow, error
        referrerPolicy: 'no-referrer', // no-referrer, *no-referrer-when-downgrade, origin, origin-when-cross-origin, same-origin, strict-origin, strict-origin-when-cross-origin, unsafe-url
        body: JSON.stringify(data) // body data type must match "Content-Type" header
    });
    return response.json(); // parses JSON response into native JavaScript objects
}

let asdf = 'not me';
postData(api_url, input_data).then((data) => {
    console.log(data.Result.Item); // JSON data parsed by `data.json()` call
    asdf = data.Result.Item;
    return data.Result.Item;
});

console.log(asdf)

// const request = new XMLHttpRequest();
// request.open('GET', api_url, false);  // `false` makes the request synchronous
// request.setRequestHeader('Accept', 'application/json')
// request.send(null);

// if (request.status === 200) {
//   console.log(request.responseText);
// }
