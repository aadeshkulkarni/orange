import { RegistrationStatusEnumType, defineConfig } from "@citrineos/base";

export function createDockerConfig() {
    return defineConfig({
        env: "development",
        provisioning: {
            heartbeatInterval: 60,
            bootRetryInterval: 15,
            unknownChargerStatus: RegistrationStatusEnumType.Accepted,
            getBaseReportOnPending: true,
            bootWithRejectedVariables: true,
            autoAccept: false,
            api: {
                endpointPrefix: "/provisioning",
                port: 8081
            }
        },
        availability: {
            api: {
                endpointPrefix: "/availability",
                port: 8081
            }
        },
        authorization: {
            api: {
                endpointPrefix: "/authorization",
                port: 8081
            }
        },
        transaction: {
            api: {
                endpointPrefix: "/transaction",
                port: 8081
            }
        },
        monitoring: {
            api: {
                endpointPrefix: "/monitoring",
                port: 8081
            }
        },
        data: {
            sequelize: {
                host: "ocpp-db",
                port: 5432,
                database: "citrine",
                dialect: "postgres",
                username: "citrine",
                password: "citrine",
                storage: "",
                sync: true,
            }
        },
        util: {
            redis: {
                host: "redis",
                port: 6379,
            },
            amqp: {
                url: "amqp://guest:guest@amqp-broker:5672",
                exchange: "citrineos",
            }
        },
        server: {
            logLevel: 3,
            host: "0.0.0.0",
            port: 8081,
            swagger: {
                enabled: true,
                path: "/docs",
                exposeData: true,
                exposeMessage: true
            }
        },
        websocketServer: {
            tlsFlag: false,
            host: "0.0.0.0",
            port: 8080,
            protocol: "ocpp2.0.1",
            pingInterval: 60,
            maxCallLengthSeconds: 5,
            maxCachingSeconds: 10
        }
    });
}