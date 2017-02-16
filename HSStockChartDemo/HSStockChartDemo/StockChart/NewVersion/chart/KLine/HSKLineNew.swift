//
//  HSKLineNew.swift
//  HSStockChartDemo
//
//  Created by Hanson on 2017/2/16.
//  Copyright © 2017年 hanson. All rights reserved.
//

import UIKit

class HSKLineNew: UIView {

    var kLineType: HSChartType = HSChartType.kLineForDay
    var theme: HSKLineTheme = HSKLineTheme()
    
    var dataK: [HSKLineModel] = []
    var positionModels: [HSKLineCoordModel] = []
    var klineModels: [HSKLineModel] = []
    
    var kLineViewTotalWidth: CGFloat = 0
    var showContentWidth: CGFloat = 0
    var contentOffsetX: CGFloat = 0
    var highLightIndex: Int = 0
    
    var maxPrice: CGFloat = 0
    var minPrice: CGFloat = 0
    var maxVolume: CGFloat = 0
    var maxMA: CGFloat = 0
    var minMA: CGFloat = 0
    var maxMACD: CGFloat = 0
    
    var priceUnit: CGFloat = 0.1
    var volumeUnit: CGFloat = 0
    
    var renderRect: CGRect = CGRect.zero
    var renderWidth: CGFloat = 0
    
    var uperChartHeight: CGFloat {
        get {
            return theme.kLineChartHeightScale * self.frame.height
        }
    }
    var lowerChartHeight: CGFloat {
        get {
            return self.frame.height * (1 - theme.kLineChartHeightScale) - theme.xAxisHeitht
        }
    }
    
    // 计算处于当前显示区域左边隐藏的蜡烛图的个数，即为当前显示的初始 index
    var startIndex: Int {
        get {
            let scrollViewOffsetX = contentOffsetX < 0 ? 0 : contentOffsetX
            var leftCandleCount = Int(abs(scrollViewOffsetX) / (theme.candleWidth + theme.candleGap))
            
            if leftCandleCount > dataK.count {
                leftCandleCount = dataK.count - 1
                return leftCandleCount
            } else if leftCandleCount == 0 {
                return leftCandleCount
            } else {
                return leftCandleCount + 1
            }
        }
    }
    
    // 当前显示区域起始横坐标 x
    var startX: CGFloat {
        get {
            let scrollViewOffsetX = contentOffsetX < 0 ? 0 : contentOffsetX
            return scrollViewOffsetX
        }
    }
    
    // 当前显示区域最多显示的蜡烛图个数
    var countOfshowCandle: Int {
        get{
            return Int((renderWidth - theme.candleWidth) / ( theme.candleWidth + theme.candleGap))
        }
    }
    
    
    // MARK: - 初始化方法
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - 绘图
    
    func drawKLineView() {
        setMaxAndMinData()
        convertToPositionModel(data: dataK)
        addKLineChartLayer(array: positionModels)
    }
    
    // MARK: - 设置当前显示区域的最大最小值
    
    func setMaxAndMinData() {
        if dataK.count > 0 {
            self.maxPrice = CGFloat.leastNormalMagnitude
            self.minPrice = CGFloat.greatestFiniteMagnitude
            self.maxVolume = CGFloat.leastNormalMagnitude
            self.maxMA = CGFloat.leastNormalMagnitude
            self.minMA = CGFloat.greatestFiniteMagnitude
            self.maxMACD = CGFloat.leastNormalMagnitude
            let startIndex = self.startIndex
            //let count = (startIndex + countOfshowCandle) > dataK.count ? dataK.count : (startIndex + countOfshowCandle)
            // 比计算出来的多加一个，是为了避免计算结果的取整导致少画
            let count = (startIndex + countOfshowCandle + 1) > dataK.count ? dataK.count : (startIndex + countOfshowCandle + 1)
            if startIndex < count {
                for i in startIndex ..< count {
                    let entity = dataK[i]
                    self.maxPrice = self.maxPrice > entity.high ? self.maxPrice : entity.high
                    self.minPrice = self.minPrice < entity.low ? self.minPrice : entity.low
                    
                    self.maxVolume = self.maxVolume > entity.volume ? self.maxVolume : entity.volume
                    
                    let tempMAMax = max(entity.ma5, entity.ma10, entity.ma20)
                    self.maxMA = self.maxMA > tempMAMax ? self.maxMA : tempMAMax
                    
                    let tempMAMin = min(entity.ma5, entity.ma10, entity.ma20)
                    self.minMA = self.minMA < tempMAMin ? self.minMA : tempMAMin
                    
                    let tempMax = max(abs(entity.diff), abs(entity.dea), abs(entity.macd))
                    self.maxMACD = tempMax > self.maxMACD ? tempMax : self.maxMACD
                }
            }
            
            self.maxPrice = self.maxPrice > self.maxMA ? self.maxPrice : self.maxMA
            self.minPrice = self.minPrice < self.minMA ? self.minPrice : self.minMA
        }
    }
    
    
    // MARK: - 转换为坐标model
    
    func convertToPositionModel(data: [HSKLineModel]) {
        
        self.positionModels.removeAll()
        self.klineModels.removeAll()
        
        let gap = theme.viewMinYGap
        let minY = gap
        let maxDiff = self.maxPrice - self.minPrice
        if maxDiff > 0, maxVolume > 0 {
            priceUnit = (uperChartHeight - 2 * minY) / maxDiff
            volumeUnit = (lowerChartHeight - theme.volumeMaxGap) / self.maxVolume
        }
        let count = (startIndex + countOfshowCandle + 1) > data.count ? data.count : (startIndex + countOfshowCandle + 1)
        if startIndex < count {
            for index in startIndex ..< count {
                let model = data[index]
                let leftPosition = startX + CGFloat(index - startIndex) * (theme.candleWidth + theme.candleGap)
                let xPosition = leftPosition + theme.candleWidth / 2.0
                
                let highPoint = CGPoint(x: xPosition, y: (maxPrice - model.high) * priceUnit + minY)
                let lowPoint = CGPoint(x: xPosition, y: (maxPrice - model.low) * priceUnit + minY)
                
                let ma5Point = CGPoint(x: xPosition, y: (maxPrice - model.ma5) * priceUnit + minY)
                let ma10Point = CGPoint(x: xPosition, y: (maxPrice - model.ma10) * priceUnit + minY)
                let ma20Point = CGPoint(x: xPosition, y: (maxPrice - model.ma20) * priceUnit + minY)
                
                let openPointY = (maxPrice - model.open) * priceUnit + minY
                let closePointY = (maxPrice - model.close) * priceUnit + minY
                var fillCandleColor = UIColor.black
                var candleRect = CGRect.zero
                
                let volume = (model.volume - 0) * volumeUnit
                let volumeStartPoint = CGPoint(x: xPosition, y: self.frame.height - volume)
                let volumeEndPoint = CGPoint(x: xPosition, y: self.frame.height)
                
                if(openPointY > closePointY) {
                    fillCandleColor = theme.candleRiseColor
                    candleRect = CGRect(x: leftPosition, y: closePointY, width: theme.candleWidth, height: openPointY - closePointY)
                    
                } else if(openPointY < closePointY) {
                    fillCandleColor = theme.candleFallColor
                    candleRect = CGRect(x: leftPosition, y: openPointY, width: theme.candleWidth, height: closePointY - openPointY)
                    
                } else {
                    candleRect = CGRect(x: leftPosition, y: closePointY, width: theme.candleWidth, height: theme.candleMinHeight)
                    if(index > 0) {
                        let preKLineModel = data[index - 1]
                        if(model.open > preKLineModel.close) {
                            fillCandleColor = theme.candleRiseColor
                        } else {
                            fillCandleColor = theme.candleFallColor
                        }
                    }
                }
                
                let positionModel = HSKLineCoordModel()
                positionModel.highPoint = highPoint
                positionModel.lowPoint = lowPoint
                positionModel.ma5Point = ma5Point
                positionModel.ma10Point = ma10Point
                positionModel.ma20Point = ma20Point
                positionModel.volumeStartPoint = volumeStartPoint
                positionModel.volumeEndPoint = volumeEndPoint
                positionModel.candleFillColor = fillCandleColor
                positionModel.candleRect = candleRect
                self.positionModels.append(positionModel)
                self.klineModels.append(model)
            }
        }
    }
    
    
    
    // 获取单个蜡烛图的layer
    func getCandleLayer(model: HSKLineCoordModel) -> CAShapeLayer {

        // K线
        let linePath = UIBezierPath(rect: model.candleRect)
        
        // 影线
        linePath.move(to: model.lowPoint)
        linePath.addLine(to: model.highPoint)
        
        let klayer = CAShapeLayer()
        klayer.path = linePath.cgPath
        klayer.strokeColor = model.candleFillColor.cgColor
        klayer.fillColor = model.candleFillColor.cgColor
        
        return klayer
    }
    
    func getVolumeLayer(model: HSKLineCoordModel) -> CAShapeLayer {
        let linePath = UIBezierPath()
        linePath.move(to: model.volumeStartPoint)
        linePath.addLine(to: model.volumeEndPoint)
        
        let vlayer = CAShapeLayer()
        vlayer.path = linePath.cgPath
        vlayer.lineWidth = theme.candleWidth
        vlayer.strokeColor = model.candleFillColor.cgColor
        vlayer.fillColor = model.candleFillColor.cgColor
        
        return vlayer
    }
    
    func addKLineChartLayer(array: [HSKLineCoordModel]) {
        self.layer.sublayers?.removeAll()
        for object in array.enumerated() {
            let candleLayer = getCandleLayer(model: object.element)
            let volumeLayer = getVolumeLayer(model: object.element)
            self.layer.addSublayer(candleLayer)
            self.layer.addSublayer(volumeLayer)
        }
    }
    

}
