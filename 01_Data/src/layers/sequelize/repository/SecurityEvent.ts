// Copyright (c) 2023 S44, LLC
// Copyright Contributors to the CitrineOS Project
//
// SPDX-License-Identifier: Apache 2.0

import { SecurityEventNotificationRequest } from "@citrineos/base";
import { SecurityEvent } from "../model/SecurityEvent";
import { SequelizeRepository } from "./Base";
import { Op } from "sequelize";
import { ISecurityEventRepository } from "../../../interfaces/repositories";

export class SecurityEventRepository extends SequelizeRepository<SecurityEvent> implements ISecurityEventRepository {
 
    async createByStationId(value: SecurityEventNotificationRequest, stationId: string): Promise<SecurityEvent | undefined> {
        return super.create(SecurityEvent.build({
            stationId: stationId,
            ...value
        }));
    }

    readByStationIdAndTimestamps(stationId: string, from?: Date, to?: Date): Promise<SecurityEvent[]> {
        const timestampQuery = this.generateTimestampQuery(from?.toISOString(), to?.toISOString());
        return this.s.models[SecurityEvent.MODEL_NAME].findAll({
            where: {
                stationId: stationId,
                ...timestampQuery
            }
        }).then(row => (row as SecurityEvent[]));
    }

    deleteByKey(key: string): Promise<boolean> {
        return super.deleteByKey(key, SecurityEvent.MODEL_NAME);
    }

    /**
     * Private Methods
     */
    private generateTimestampQuery(from?: string, to?: string): any {
        if (!from && !to) {
            return {};
        }
        if (!from && to) {
            return { timestamp: { [Op.lte]: to } };
        }
        if (from && !to) {
            return { timestamp: { [Op.gte]: from } };
        }
        return { timestamp: { [Op.between]: [from, to] } };
    }
}