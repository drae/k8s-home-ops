import * as m from 'zigbee-herdsman-converters/lib/modernExtend';

export default {
    zigbeeModel: ['EGLO_ZM_TW'],
    model: '33955',
    whiteLabel: [
        {vendor: "EGLO", model: "900316"},
        {vendor: "EGLO", model: "900317"},
        {vendor: "EGLO", model: "900053"},
    ],
    vendor: 'AwoX',
    description: 'FUEVA-Z Ceiling Light',
    extend: [m.light({colorTemp: {range: [153, 370]}, turnsOffAtBrightness1: true})],
};