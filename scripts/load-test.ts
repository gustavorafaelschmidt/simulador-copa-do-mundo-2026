import "dotenv/config";
import autocannon from "autocannon";

const targetUrl =
  process.env.LOAD_TEST_URL ?? `http://localhost:${process.env.SOCKET_PORT ?? "4001"}/health`;

const result = await autocannon({
  url: targetUrl,
  connections: 50,
  duration: 10
});

console.log(autocannon.printResult(result));