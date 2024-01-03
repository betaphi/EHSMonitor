//
//  EHSController.swift
//
//
//  Created by Bastian Rössler on 03.01.24.
//

import Foundation
import NASAKit

final class EHSController
{
    private var nasaTask: Task<Void, Never>?
    
    @Measurement public private(set) var operationMode: OperationMode?
    @Measurement public private(set) var compressorStatus: CompressorState?
    @Measurement public private(set) var hotGasStatus: HotGasState?
    @Measurement public private(set) var liquidValveStatus: LiquidValveState?
    @Measurement public private(set) var eviBypassStatus: EVIBypassState?
    @Measurement public private(set) var fourWayValveStatus: FourWayValveState?
    @Measurement public private(set) var baseHeaterStatus: BaseHeaterState?
    @Measurement public private(set) var pheHeaterStatus: PHEHeaterState?
    @Measurement public private(set) var compressorOrderFrequency: Int?
    @Measurement public private(set) var compressorTargetFrequency: Int?
    @Measurement public private(set) var compressorCurrentFrequency: Int?
    
    @Measurement public private(set) var outdoorTemperature: Double?
    @Measurement public private(set) var highPressure: Double?
    @Measurement public private(set) var lowPressure: Double?
    @Measurement public private(set) var dischargeTemperature: Double?
    @Measurement public private(set) var mainEEV: Int?
    @Measurement public private(set) var eviEEV: Int?
    
    @Measurement public private(set) var mcuHRBypassEEV: Int?
    @Measurement public private(set) var eviSolEEV: Int?
    @Measurement public private(set) var outdoorFanRPM: Int?
    @Measurement public private(set) var compressorTopTemperature: Double?
    @Measurement public private(set) var highPressureSaturationTemperature: Double?
    @Measurement public private(set) var lowPressureSaturationTemperature: Double?
    @Measurement public private(set) var condensatorOutTempeature: Double?
    @Measurement public private(set) var eviInTemperature: Double?
    @Measurement public private(set) var eviOutTemperature: Double?
    @Measurement public private(set) var suctionTemperature: Double?
    @Measurement public private(set) var liquidTubeTemperature: Double?
    @Measurement public private(set) var compressorOct1: Double?
    @Measurement public private(set) var dischargeSuperHeatControlTemperature: Double?
    @Measurement public private(set) var suction2_1secTemperature: Double?
    @Measurement public private(set) var inverterTemperature: Double?
    @Measurement public private(set) var evaporatorInTemperature: Double?
    @Measurement public private(set) var errorCode: UInt16?
    
    @Measurement public private(set) var waterFlowRate: Double? {
        didSet {
            self.updateHeatOutput()
        }
    }
    @Measurement public private(set) var pwmPercentage: UInt8?
    @Measurement public private(set) var threeWayValvePosition: ThreeWayValvePosition?
    @Measurement public private(set) var capacityRequest: Double?
    @Measurement public private(set) var capacityAbsolute: Double?
    @Measurement public private(set) var centralHeatingStatus: CentralHeatingStatus?
    @Measurement public private(set) var targetFlowTemperature: Double?
    @Measurement public private(set) var flowTemperature: Double? {
        didSet {
            self.updateHeatOutput()
        }
    }
    @Measurement public private(set) var returnTemperature: Double? {
        didSet {
            self.updateHeatOutput()
        }
    }
    @Measurement public private(set) var dhwStatus: DHWStatus?
    @Measurement public private(set) var targetDHWTemperature: Double?
    @Measurement public private(set) var dhwTemperature: Double?
    @Measurement public private(set) var defrostStatus: DefrostStatus?
    @Measurement public private(set) var heatOutput: Double?
    
    public init(
        configuration: Configuration.EHS,
        mqttController: MQTTController
    ) {
        self._operationMode = .init(mqtt: .init(controller: mqttController, topic: "samsung/operationMode"))
        self._compressorStatus = .init(validity: 6*60+10, mqtt: .init(controller: mqttController, topic: "samsung/compressorStatus"))
        self._hotGasStatus = .init(mqtt: .init(controller: mqttController, topic: "samsung/hotGasStatus"))
        self._liquidValveStatus = .init(mqtt: .init(controller: mqttController, topic: "samsung/liquidValveStatus"))
        self._eviBypassStatus = .init(mqtt: .init(controller: mqttController, topic: "samsung/eviBypassStatus"))
        self._fourWayValveStatus = .init(mqtt: .init(controller: mqttController, topic: "samsung/fourWayValveStatus"))
        self._baseHeaterStatus = .init(mqtt: .init(controller: mqttController, topic: "samsung/baseHeaterStatus"))
        self._pheHeaterStatus = .init(mqtt: .init(controller: mqttController, topic: "samsung/pheHeaterStatus"))
        self._compressorOrderFrequency = .init(mqtt: .init(controller: mqttController, topic: "samsung/compressorOrderFreq"))
        self._compressorTargetFrequency = .init(mqtt: .init(controller: mqttController, topic: "samsung/compressorTargetFreq"))
        self._compressorCurrentFrequency = .init(mqtt: .init(controller: mqttController, topic: "samsung/compressorCurrentFreq"))
        self._outdoorTemperature = .init(mqtt: .init(controller: mqttController, topic: "samsung/outdoorTemp"))
        self._highPressure = .init(mqtt: .init(controller: mqttController, topic: "samsung/highPressure"))
        self._lowPressure = .init(mqtt: .init(controller: mqttController, topic: "samsung/lowPressure"))
        self._mainEEV = .init(mqtt: .init(controller: mqttController, topic: "samsung/mainEEV"))
        self._eviEEV = .init(mqtt: .init(controller: mqttController, topic: "samsung/eviEEV"))
        self._mcuHRBypassEEV = .init(mqtt: .init(controller: mqttController, topic: "samsung/mcuHRBypassEEV"))
        self._eviSolEEV = .init(mqtt: .init(controller: mqttController, topic: "samsung/eviSolEEV"))
        self._outdoorFanRPM = .init(mqtt: .init(controller: mqttController, topic: "samsung/outdoorFanRPM"))
        self._compressorTopTemperature = .init(mqtt: .init(controller: mqttController, topic: "samsung/compressorTopTemperature"))
        self._highPressureSaturationTemperature = .init(mqtt: .init(controller: mqttController, topic: "samsung/highPressureSaturationTemperature"))
        self._lowPressureSaturationTemperature = .init(mqtt: .init(controller: mqttController, topic: "samsung/lowPressureSaturationTemperature"))
        self._dischargeTemperature = .init(mqtt: .init(controller: mqttController, topic: "samsung/dischargeTemperature"))
        self._condensatorOutTempeature = .init(mqtt: .init(controller: mqttController, topic: "samsung/condensatorOutTemperature"))
        self._eviInTemperature = .init(mqtt: .init(controller: mqttController, topic: "samsung/eviInTemperature"))
        self._eviOutTemperature = .init(mqtt: .init(controller: mqttController, topic: "samsung/eviOutTemperature"))
        self._suctionTemperature = .init(mqtt: .init(controller: mqttController, topic: "samsung/suctionTemperature"))
        self._liquidTubeTemperature = .init(mqtt: .init(controller: mqttController, topic: "samsung/liquidTubeTemperature"))
        self._compressorOct1 = .init(mqtt: .init(controller: mqttController, topic: "samsung/compressorOct1"))
        self._dischargeSuperHeatControlTemperature = .init(mqtt: .init(controller: mqttController, topic: "samsung/dshTemperature"))
        self._suction2_1secTemperature = .init(mqtt: .init(controller: mqttController, topic: "samsung/suction2_1secTemperature"))
        self._inverterTemperature = .init(mqtt: .init(controller: mqttController, topic: "samsung/inverterTemperature"))
        self._evaporatorInTemperature = .init(mqtt: .init(controller: mqttController, topic: "samsung/evaInTemperature"))
        self._errorCode = .init(mqtt: .init(controller: mqttController, topic: "samsung/errorCode"))
        self._waterFlowRate = .init(validity: 60, mqtt: .init(controller: mqttController, topic: "samsung/waterFlowRate"))
        self._pwmPercentage = .init(validity: 6*60+10, mqtt: .init(controller: mqttController, topic: "samsung/pwm"))
        self._threeWayValvePosition = .init(validity: 6*60+10, mqtt: .init(controller: mqttController, topic: "samsung/threeWayValve", transform: { "\($0.rawValue)" }))
        self._capacityRequest = .init(validity: 6*60+10, mqtt: .init(controller: mqttController, topic: "samsung/capacity/request"))
        self._capacityAbsolute = .init(validity: 6*60+10, mqtt: .init(controller: mqttController, topic: "samsung/capacity/absolute"))
        self._centralHeatingStatus = .init(validity: 6*60+10, mqtt: .init(controller: mqttController, topic: "samsung/centralHeatingStatus"))
        self._targetFlowTemperature = .init(validity: 6*60+10, mqtt: .init(controller: mqttController, topic: "samsung/targetFlowTemperature"))
        self._flowTemperature = .init(mqtt: .init(controller: mqttController, topic: "samsung/flowTemperature"))
        self._returnTemperature = .init(mqtt: .init(controller: mqttController, topic: "samsung/returnTemperature"))
        self._dhwStatus = .init(mqtt: .init(controller: mqttController, topic: "samsung/dhwStatus"))
        self._targetDHWTemperature = .init(validity: 6*60+10, mqtt: .init(controller: mqttController, topic: "samsung/targetDHWTemperature"))
        self._dhwTemperature = .init(validity: 90, mqtt: .init(controller: mqttController, topic: "samsung/dhwTemperature"))
        self._defrostStatus = .init(mqtt: .init(controller: mqttController, topic: "samsung/defrostStatus", transform: { "\($0.mqttState)" }))
        self._heatOutput = .init(mqtt: .init(controller: mqttController, topic: "samsung/heatOutput"))
        
        self.nasaTask = Task { [weak self] in
            guard let self = self else { return }
            
            
            let nasaController: NASAController
            do {
                nasaController = try NASAController(device: configuration.nasaDevice, writeRawDataPath: configuration.rawNasaWritePath, enableDebugLogging: false)
            } catch {
                logger.error("Initialize NASAController: \(error)")
                fatalError("Error initializing NASAController")
            }
            
            for await packet in nasaController.packets
            {
                do {
                    try await self.process(packet: packet)
                } catch {
                    logger.error("Processing Packet: \(error)")
                }
            }
        }
        
    }
    
    // MARK: - Refresh Methods
    private func process(packet: Packet) async throws
    {
        switch packet.source.class
        {
        case .outdoor, .indoor:
            break
        default:
            // ignore all packets that are not coming from outdoor or indoor unit
            return
        }
        
        if let operationModeRaw = packet.messages.getENUM_out_operation_odu_mode(),
           let operationMode = OperationMode(rawValue: UInt16(operationModeRaw.rawValue))
        {
            logger.trace("Operation Mode: \(operationMode)")
            self.operationMode = operationMode
        }
        
        if let compressorStatusRaw = packet.messages.getENUM_out_load_comp1()
        {
            let compressorStatus: CompressorState = compressorStatusRaw ? .on : .off
            logger.trace("Compressor Status: \(compressorStatus)")
            self.compressorStatus = compressorStatus
        }
        
        if let hotGasStatusRaw = packet.messages.getENUM_out_load_hotgas()
        {
            let hotGasStatus: HotGasState = hotGasStatusRaw ? .on : .off
            logger.trace("HotGas Status: \(hotGasStatus)")
            self.hotGasStatus = hotGasStatus
        }
        
        if let liquidValveStatusRaw = packet.messages.getENUM_OUT_LOAD_LIQUID()
        {
            let liquidValveStatus: LiquidValveState = liquidValveStatusRaw ? .on : .off
            logger.trace("LiquidValve Status: \(liquidValveStatus)")
            self.liquidValveStatus = liquidValveStatus
        }
        
        if let eviBypassStatusRaw = packet.messages.getENUM_out_load_evi_bypass()
        {
            let eviBypassStatus: EVIBypassState = eviBypassStatusRaw ? .on : .off
            logger.trace("EVIBypass Status: \(eviBypassStatus)")
            self.eviBypassStatus = eviBypassStatus
        }
        
        if let fourWayValveStatusRaw = packet.messages.getENUM_out_load_4way()
        {
            let fourWayValveStatus: FourWayValveState = fourWayValveStatusRaw ? .on : .off
            logger.trace("FourWayValve Status: \(fourWayValveStatus)")
            self.fourWayValveStatus = fourWayValveStatus
        }
        
        if let baseHeaterStatusRaw = packet.messages.getENUM_OUT_LOAD_BASEHEATER()
        {
            let baseHeaterStatus: BaseHeaterState = baseHeaterStatusRaw ? .on : .off
            logger.trace("BaseHeater Status: \(baseHeaterStatus)")
            self.baseHeaterStatus = baseHeaterStatus
        }
        
        if let pheHeaterStatusRaw = packet.messages.getENUM_OUT_LOAD_PHEHEATER()
        {
            let pheHeaterStatus: PHEHeaterState = pheHeaterStatusRaw ? .on : .off
            logger.trace("PHEHeater Status: \(pheHeaterStatus)")
            self.pheHeaterStatus = pheHeaterStatus
        }
        
        if let outdoorTemp = packet.messages.getVAR_out_sensor_airout()
        {
            logger.trace("Outdoor Temperature [°C]: \(outdoorTemp)")
            self.outdoorTemperature = outdoorTemp
        }
        
        if let highPressure = packet.messages.getVAR_out_sensor_highpress()
        {
            logger.trace("High Pressure [kgf/cm^2]: \(highPressure)")
            self.highPressure = highPressure
        }
        
        if let lowPressure = packet.messages.getVAR_out_sensor_lowpress()
        {
            logger.trace("Low Pressure [kgf/cm^2]: \(lowPressure)")
            self.lowPressure = lowPressure
        }
        
        if let dischargeTemp = packet.messages.getVAR_out_sensor_discharge1()
        {
            logger.trace("Discharge Temperature [°C]: \(dischargeTemp)")
            self.dischargeTemperature = dischargeTemp
        }
        
        // EEV values
        if let mainEEV1 = packet.messages.getVAR_out_load_outeev1()
        {
            logger.trace("Main EEV1: \(mainEEV1)")
            self.mainEEV = Int(mainEEV1)
        }
        
        if let eviEEV = packet.messages.getVAR_out_load_evieev()
        {
            logger.trace("EVI EEV: \(eviEEV)")
            self.eviEEV = Int(eviEEV)
        }
        
        if let mcuHRBypassEEV = packet.messages.getVAR_OUT_LOAD_MCU_HR_BYPASS_EEV()
        {
            logger.trace("MCU HR Bypass EEV: \(mcuHRBypassEEV)")
            self.mcuHRBypassEEV = Int(mcuHRBypassEEV)
        }
        
        if let eviSolEEV = packet.messages.getVAR_OUT_LOAD_EVI_SOL_EEV()
        {
            logger.trace("EVI Sol EEV: \(eviSolEEV)")
            self.eviSolEEV = Int(eviSolEEV)
        }
        
        if let compressorOrderFrequency = packet.messages.getVAR_out_control_order_cfreq_comp1()
        {
            logger.trace("Compressor Order Frequency [Hz]: \(compressorOrderFrequency)")
            self.compressorOrderFrequency = Int(compressorOrderFrequency)
        }
        
        if let compressorTargetFrequency = packet.messages.getVAR_out_control_target_cfreq_comp1()
        {
            logger.trace("Compressor Target Frequency [Hz]: \(compressorTargetFrequency)")
            self.compressorTargetFrequency = Int(compressorTargetFrequency)
        }
        
        if let compressorCurrentFrequency = packet.messages.getVAR_out_control_cfreq_comp1()
        {
            logger.trace("Compressor Current Frequency [Hz]: \(compressorCurrentFrequency)")
            self.compressorCurrentFrequency = Int(compressorCurrentFrequency)
        }
        
        if let outdoorFanRPM = packet.messages.getVAR_out_load_fanrpm1()
        {
            logger.trace("Outdoor FAN RPM [Hz]: \(outdoorFanRPM)")
            self.outdoorFanRPM = Int(outdoorFanRPM)
        }
        
        if let compressorTopTemperature = packet.messages.getVAR_out_sensor_top1()
        {
            logger.trace("Compressor Top Temperature [°C]: \(compressorTopTemperature)")
            self.compressorTopTemperature = compressorTopTemperature
        }
        
        if let highPressureSaturationTemperature = packet.messages.getVAR_out_sensor_sat_temp_high_pressure()
        {
            logger.trace("High Pressure Saturation Temperature [°C]: \(highPressureSaturationTemperature)")
            self.highPressureSaturationTemperature = highPressureSaturationTemperature
        }
        
        if let lowPressureSaturationTemperature = packet.messages.getVAR_out_sensor_sat_temp_low_pressure()
        {
            logger.trace("Low Pressure Saturation Temperature [°C]: \(lowPressureSaturationTemperature)")
            self.lowPressureSaturationTemperature = lowPressureSaturationTemperature
        }
        
        if let compressorCurrent = packet.messages.getVAR_out_sensor_ct1()
        {
            logger.trace("Compressor Current [A]: \(compressorCurrent)")
        }
        
        if let condensatorOutTemp = packet.messages.getVAR_out_sensor_condout()
        {
            logger.trace("Condensator Out (CondOut) Temperature  [°C]: \(condensatorOutTemp)")
            self.condensatorOutTempeature = condensatorOutTemp
        }
        
        if let suctionTemp = packet.messages.getVAR_out_sensor_suction()
        {
            logger.trace("Suction Temperature [°C]: \(suctionTemp)")
            self.suctionTemperature = suctionTemp
        }
        
        if let liquidTubeTemperature = packet.messages.getVAR_out_sensor_doubletube()
        {
            logger.trace("Liquid Tube Temperature [°C]: \(liquidTubeTemperature)")
            self.liquidTubeTemperature = liquidTubeTemperature
        }
        
        if let dshTemperature = packet.messages.getVAR_out_control_dsh1()
        {
            logger.trace("DSH Temperature [°C]: \(dshTemperature)")
            self.dischargeSuperHeatControlTemperature = dshTemperature
        }
        
        if let suction2_1secTemperature = packet.messages.getVAR_out_sensor_suction2_1sec()
        {
            logger.trace("Suction2 1sec Temperature [°C]: \(suction2_1secTemperature)")
            self.suction2_1secTemperature = suction2_1secTemperature
        }
        
        if let eviInTemp = packet.messages.getVAR_outcd__sensor_eviin()
        {
            logger.trace("EVI In Temperature [°C]: \(eviInTemp)")
            self.eviInTemperature = eviInTemp
        }
        
        if let eviOutTemp = packet.messages.getVAR_out_sensor_eviout()
        {
            logger.trace("EVI Out Temperature [°C]: \(eviOutTemp)")
            self.eviOutTemperature = eviOutTemp
        }
        
        if let errorCode = packet.messages.getVAR_out_error_code()
        {
            logger.trace("Error Code: \(errorCode)")
            self.errorCode = errorCode
        }
        
        if let dcLinkVoltage = packet.messages.getVAR_out_sensor_dclink_voltage()
        {
            logger.trace("DC Link Voltage: \(dcLinkVoltage)")
        }
        
        if let evaInTemperature = packet.messages.getVAR_OUT_SENSOR_EVAIN()
        {
            logger.trace("EVA In Temperature [°C]: \(evaInTemperature)")
            self.evaporatorInTemperature = evaInTemperature
        }
        
        if let inverterTemperature = packet.messages.getVAR_out_sensor_IPM1()
        {
            logger.trace("Inverter Temperature [°C]: \(inverterTemperature)")
            self.inverterTemperature = inverterTemperature
        }
        
        if let compressorOct1 = packet.messages.getVAR_OUT_SENSOR_OCT1()
        {
            logger.trace("Compressor OCT1: \(compressorOct1)")
            self.compressorOct1 = compressorOct1
        }
        
        if let flowTemperature = packet.messages.getVAR_OUT_SENSOR_TW2()
        {
            logger.trace("FlowTemperature: \(flowTemperature)")
            self.flowTemperature = flowTemperature
        }
        
        if let returnTemperature = packet.messages.getVAR_OUT_SENSOR_TW1()
        {
            logger.trace("ReturnTemperature: \(returnTemperature)")
            self.returnTemperature = returnTemperature
        }
        
        // MARK: Indoor values
        if let waterFlowRate = packet.messages.getVAR_IN_FLOW_SENSOR_CALC()
        {
            logger.trace("WaterFlowRate: \(waterFlowRate)")
            self.waterFlowRate = waterFlowRate
        }
        
        if let pwm = packet.messages.getENUM_IN_WATERPUMP_PWM_VALUE()
        {
            logger.trace("PWM Pump: \(pwm)")
            self.pwmPercentage = pwm
        }
        
        if let threeWayValvePositionRaw = packet.messages.getENUM_IN_3WAY_VALVE()
        {
            let threeWayValvePosition: ThreeWayValvePosition = switch threeWayValvePositionRaw {
            case .Room:
                .centralHeating
            case .Tank:
                .dhw
            }
            logger.trace("ThreeWayValvePosition: \(threeWayValvePosition)")
            self.threeWayValvePosition = threeWayValvePosition
        }
        
        if let capacityRequest = packet.messages.getVAR_in_capacity_request()
        {
            logger.trace("CapacityRequest: \(capacityRequest)")
            self.capacityRequest = capacityRequest
        }
        
        if let capacityAbsolute = packet.messages.getVAR_in_capacity_absolute()
        {
            logger.trace("CapacityAbsolute: \(capacityAbsolute)")
            self.capacityAbsolute = capacityAbsolute
        }
        
        if let targetFlowTemperature = packet.messages.getVAR_IN_TEMP_WATER_OUTLET_TARGET_F()
        {
            logger.trace("TargetFlowTemperature: \(targetFlowTemperature)")
            self.targetFlowTemperature = targetFlowTemperature
        }
        
        if let targetDHWTemperature = packet.messages.getVAR_IN_TEMP_WATER_HEATER_TARGET_F()
        {
            logger.trace("DHWTargetTemperature: \(targetDHWTemperature)")
            self.targetDHWTemperature = targetDHWTemperature
        }
        
        if let dhwTemperature = packet.messages.getVAR_IN_TEMP_WATER_TANK_F()
        {
            logger.trace("DHWTemperature: \(dhwTemperature)")
            self.dhwTemperature = dhwTemperature
        }
        
        if let defrostStatusRaw = packet.messages.getENUM_OUT_DEICE_STEP_INDOOR()
        {
            let defrostStatus: DefrostStatus = {
                switch defrostStatusRaw
                {
                case .defrostStage1:
                    return .defrosting(stage: .stage1)
                case .defrostStage2:
                    return .defrosting(stage: .stage2)
                case .defrostStage3:
                    return .defrosting(stage: .stage3)
                case .defrostStage4:
                    return .defrosting(stage: .stage4)
                case .defrostFinalStage:
                    return .defrosting(stage: .finalStage)
                case .noDefrostOperation:
                    return .idle
                }
            }()
            
            logger.trace("DefrostStatus: \(defrostStatus)")
            self.defrostStatus = defrostStatus
        }
        
    }
    
    private func updateHeatOutput()
    {
        guard let flowTemperature = self.flowTemperature,
              let returnTemperature = self.returnTemperature,
              let waterFlowRate = self.waterFlowRate
        else {
            return
        }
        
        let heatOutput = (flowTemperature - returnTemperature) * (waterFlowRate/60) * 4190
        logger.trace("HeatOutput: \(heatOutput)")
        self.heatOutput = heatOutput
    }
    
}

// MARK: - Auxilary Types
extension EHSController
{
    enum OperationMode: UInt16
    {
        case stop = 0
        case safety = 1
        case normal = 2
        case balance = 3
        case recovery = 4
        case deice = 5
        case compdown = 6
        case prohibit = 7
        case linejig = 8 // test?
        case pcbjig = 9 // test?
        case test = 10
        case charge = 11
        case pumpdown = 12
        case pumpout = 13
        case vacuum = 14
        case caloryjig = 15
        case pumpdownstop = 16
        case substop = 17
        case checkpipe = 18
        case checkref = 19
        case fptjig = 20
        case nonstop_heat_cool_change = 21
        case auto_inspect = 22
        case electric_discharge = 23
        case split_deice = 24
        case inverter_check = 25
        case nonstop_deice = 26
        case rem_test = 27
        case rating = 28
        case pc_test = 29
        case pumpdown_thermooff = 30
        case three_phase_test = 31
        case smartinstall_test = 32
        case device_performance_test = 33
        case inverter_fan_pba_check = 34
        case auto_pip_pairing = 35
        case auto_charge = 36
        case unknown = 255
        
        static func fromRawValue(_ rawValue: UInt16) -> OperationMode
        {
            if let value = OperationMode(rawValue: rawValue)
            {
                return value
            }
            else
            {
                return .unknown
            }
        }
    }
    
    enum CompressorState: UInt16
    {
        case off = 0
        case on = 1
    }
    
    enum HotGasState: UInt16
    {
        case off = 0
        case on = 1
    }
    
    enum LiquidValveState: UInt16
    {
        case off = 0
        case on = 1
    }
    
    enum EVIBypassState: UInt16
    {
        case off = 0
        case on = 1
    }
    
    enum FourWayValveState: UInt16
    {
        case off = 0
        case on = 1
    }
    
    enum BaseHeaterState: UInt16
    {
        case off = 0
        case on = 1
    }
    
    enum PHEHeaterState: UInt16
    {
        case off = 0
        case on = 1
    }
    
    
    
    enum ThreeWayValvePosition: UInt16
    {
        case centralHeating = 0
        case dhw = 1
    }
    
    enum CentralHeatingStatus: UInt16
    {
        case off = 0
        case on = 1
    }
    
    enum DHWStatus: UInt16
    {
        case off = 0
        case on = 1
    }
    
    enum DefrostStatus: Equatable
    {
        case idle
        case defrosting(stage: DefrostStage)
        
        enum DefrostStage: UInt16, Equatable
        {
            case stage1 = 1
            case stage2 = 2
            case stage3 = 3
            case stage4 = 4
            case finalStage = 7
        }
        
        var mqttState: UInt16 {
            switch self {
            case .idle:
                return 0
            case .defrosting(let stage):
                return stage.rawValue
            }
        }
    }
    
    enum ReadError: Error
    {
        case invalidValue(description: String, rawValue: UInt16)
    }
}
