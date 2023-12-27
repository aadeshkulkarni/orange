/**
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Copyright (c) 2023 S44, LLC
 */

import { CustomDataType, IdTokenType, IdTokenInfoType, AuthorizationData, Namespace, ConnectorEnumType } from '@citrineos/base';
import { Table, Column, Model, ForeignKey, BelongsTo, DataType } from 'sequelize-typescript';
import { IdToken } from './IdToken';
import { IdTokenInfo } from './IdTokenInfo';
import { AuthorizationRestrictions } from '../../../../interfaces';

@Table
export class Authorization extends Model implements AuthorizationData, AuthorizationRestrictions {

    static readonly MODEL_NAME: string = Namespace.AuthorizationData;

    declare customData?: CustomDataType;

    @Column(DataType.ARRAY(DataType.STRING))
    declare allowedConnectorTypes?: string[];

    @Column(DataType.ARRAY(DataType.STRING))
    declare disallowedEvseIdPrefixes?: string[];

    @ForeignKey(() => IdToken)
    @Column({
        type: DataType.INTEGER,
        unique: true
    })
    declare idTokenId?: number;

    @BelongsTo(() => IdToken)
    declare idToken: IdTokenType;

    @ForeignKey(() => IdTokenInfo)
    @Column(DataType.INTEGER)
    declare idTokenInfoId?: number;

    @BelongsTo(() => IdTokenInfo)
    declare idTokenInfo?: IdTokenInfoType;
}

