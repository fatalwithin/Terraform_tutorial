import * as express from 'express';

const port = process.env.PORT ?? 8080;

const app = express();

app.use((req: express.Request, res: express.Response) => {
	res.send('Welcome to Sample APP 2');
});

app.listen(port, () => {
	console.info('HTTP server is running on port', port);
});
