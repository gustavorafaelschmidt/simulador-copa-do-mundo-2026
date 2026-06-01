declare module "autocannon" {
  export type AutocannonOptions = {
    url: string;
    connections?: number;
    duration?: number;
    pipelining?: number;
    method?: string;
    headers?: Record<string, string>;
    body?: string;
  };

  export type AutocannonMetric = {
    average?: number;
    mean?: number;
    stddev?: number;
    min?: number;
    max?: number;
    total?: number;
    p0_001?: number;
    p0_01?: number;
    p0_1?: number;
    p1?: number;
    p2_5?: number;
    p10?: number;
    p25?: number;
    p50?: number;
    p75?: number;
    p90?: number;
    p97_5?: number;
    p99?: number;
    p99_9?: number;
    p99_99?: number;
    p99_999?: number;
  };

  export type AutocannonResult = {
    url?: string;
    socketPath?: string;
    connections?: number;
    duration?: number;
    pipelining?: number;
    workers?: number;
    requests: AutocannonMetric;
    latency: AutocannonMetric;
    throughput: AutocannonMetric;
    errors: number;
    timeouts: number;
    mismatches: number;
    non2xx: number;
    resets: number;
  };

  export type Autocannon = {
    (options: AutocannonOptions): Promise<AutocannonResult>;
    printResult(result: AutocannonResult): string;
  };

  const autocannon: Autocannon;

  export default autocannon;
}
