const http = require('http');

exports.handler = async (event, context, callback) => {
    console.info('event: ', event);
    const message = JSON.stringify(event.key);

    console.info('method: ', event.method);
    console.info('host: ', event.host);
    console.info('path: ', event.path);

    return new Promise((resolve, reject) => {
        const options = {
            host: event.host,
            path: `${event.path}`,
            method: event.method,
            headers: {
                'Content-Type': 'application/json',
            }
        };

        const req = http.request(options, (res) => {
            console.info('Success');
            resolve('Success');
        });

        req.on('error', (e) => {
            console.info('Error: ', e.message);
            reject(e.message);
        });

        req.write('');
        req.end();
    });
};
