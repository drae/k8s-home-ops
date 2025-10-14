const fz = require('zigbee-herdsman-converters/converters/fromZigbee');
const tz = require('zigbee-herdsman-converters/converters/toZigbee');
const exposes = require('zigbee-herdsman-converters/lib/exposes');
const reporting = require('zigbee-herdsman-converters/lib/reporting');
const extend = require('zigbee-herdsman-converters/lib/extend');
const e = exposes.presets;
const ea = exposes.access;

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
    extend: extend.light_onoff_brightness_colortemp_color({colorTempRange: [153, 370], supportsHueAndSaturation: true}),
    meta: { turnsOffAtBrightness1: true },
};