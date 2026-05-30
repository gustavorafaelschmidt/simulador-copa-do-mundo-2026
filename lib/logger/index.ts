type LogLevel = "debug" | "info" | "warn" | "error";

type LogMetadata = Record<string, unknown>;

function writeLog(level: LogLevel, message: string, metadata?: LogMetadata) {
  const entry = {
    level,
    message,
    timestamp: new Date().toISOString(),
    ...(metadata ? { metadata } : {})
  };

  /*
    Em produção, logs estruturados em JSON facilitam envio para serviços externos.
    Futuramente pode ser substituído por Pino, Winston, Datadog, OpenTelemetry etc.
  */
  if (process.env.NODE_ENV === "production") {
    console[level](JSON.stringify(entry));
    return;
  }

  console[level](`[${entry.timestamp}] ${level.toUpperCase()} ${message}`, metadata ?? "");
}

export const logger = {
  debug(message: string, metadata?: LogMetadata) {
    writeLog("debug", message, metadata);
  },

  info(message: string, metadata?: LogMetadata) {
    writeLog("info", message, metadata);
  },

  warn(message: string, metadata?: LogMetadata) {
    writeLog("warn", message, metadata);
  },

  error(message: string, metadata?: LogMetadata) {
    writeLog("error", message, metadata);
  }
};