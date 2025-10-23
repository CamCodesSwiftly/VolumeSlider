// The Swift Programming Language

// https://docs.swift.org/swift-book

import SwiftUI

public struct VolumeSlider<V>: View where V : BinaryFloatingPoint, V.Stride : BinaryFloatingPoint {
  
  // MARK: - Value
  // MARK: Private
  @Binding private var value: V
  private let bounds: ClosedRange<V>
  private let step: V.Stride
  private var activeBackgroundGradient: LinearGradient?
  private var passiveBackgroundGradient: LinearGradient?
  private var activeBackgroundColor: Color?
  private var passiveBackgroundColor: Color?
  private var buttonGradient: LinearGradient?
  private var buttonColor: Color?
  private var textColor: Color
  
  
  private let length: CGFloat    = 60
  
  @State private var ratio: CGFloat   = 0
  @State private var startX: CGFloat? = nil
  
  private var buttonBackground: AnyShapeStyle {
    if let buttonColor {
      return AnyShapeStyle(buttonColor)
    }
    else if let buttonGradient {
      return AnyShapeStyle(buttonGradient)
    }
    else {
      return AnyShapeStyle(Color.purple)
    }
  }
  
  
  private var activeBackground: AnyShapeStyle {
    if let activeBackgroundColor {
      return AnyShapeStyle(activeBackgroundColor)
    }
    else if let activeBackgroundGradient {
      return AnyShapeStyle(activeBackgroundGradient)
    }
    else {
      return AnyShapeStyle(Color.orange)
    }
  }
  
  private var passiveBackground: AnyShapeStyle {
    if let passiveBackgroundColor {
      return AnyShapeStyle(passiveBackgroundColor)
    }
    else if let passiveBackgroundGradient {
      return AnyShapeStyle(passiveBackgroundGradient)
    }
    else {
      return AnyShapeStyle(Color.gray)
    }
  }
  
  private var icon: String {
    switch value {
    case 0:            return "speaker.slash.fill"
    case 0.01..<0.33:  return "speaker.wave.1.fill"
    case 0.33..<0.66:  return "speaker.wave.2.fill"
    default:           return "speaker.wave.3.fill"
    }
  }
  
  
  // MARK: - Initializer
  public init(
    value: Binding<V>,
    in bounds: ClosedRange<V>,
    step: V.Stride                             = 1,
    activeBackgroundGradient: LinearGradient?  = nil,
    passiveBackgroundGradient: LinearGradient? = nil,
    activeBackgroundColor: Color?              = nil,
    passiveBackgroundColor: Color?             = nil,
    buttonGradient: LinearGradient?            = nil,
    buttonColor: Color?                        = nil,
    textColor: Color
  ) {
    _value  = value
    
    self.bounds                    = bounds
    self.step                      = step
    self.activeBackgroundGradient  = activeBackgroundGradient
    self.passiveBackgroundGradient = passiveBackgroundGradient
    self.activeBackgroundColor     = activeBackgroundColor
    self.passiveBackgroundColor    = passiveBackgroundColor
    self.buttonGradient            = buttonGradient
    self.buttonColor               = buttonColor
    self.textColor                 = textColor
  }
  
  
  // MARK: - View
  // MARK: Public
  public var body: some View {
    VStack {
      ZStack {
        volumeOffLabel(value: value)
          .padding(.horizontal, 30)
          .opacity(value <= 0 ? 1 :0)
          .zIndex(5)
        GeometryReader { proxy in
          ZStack(alignment: .leading) {
            HStack(spacing: 0) {
              RoundedRectangle(cornerRadius: length/2)
                .fill(activeBackground)
                .frame(width: (proxy.size.width - length) * ratio + length)
              
              RoundedRectangle(cornerRadius: 0)
                .fill(Color.gray)
                .padding(.leading, -(length/2))
            }
            ZStack {
              Circle()
                .fill(buttonBackground)
                .frame(height: length)
              Image(systemName: icon)
                .foregroundColor(textColor)
            }
            .offset(x: (proxy.size.width - length) * ratio)
            .gesture(DragGesture(minimumDistance: 0)
              .onChanged({ updateStatus(value: $0, proxy: proxy) })
              .onEnded { _ in startX = nil })
          }
          .frame(width: (proxy.size.width), height: length)
          .clipShape(RoundedRectangle(cornerRadius: length))
          .simultaneousGesture(
            DragGesture(minimumDistance: 0)
              .onChanged({update(value: $0, proxy: proxy)})
          )
          .onAppear {
            ratio = min(1, max(0,CGFloat(value / bounds.upperBound)))
          }
        }
      }
    }
    .frame(height: length)
  }
  
  // MARK: Private
  
  private func volumeOffLabel(value: V) -> some View {
    HStack {
      Spacer()
      Text("Off")
        .shadow(color: .black.opacity(0.9), radius: 2, x: 1, y: 1)
        .foregroundStyle(Color.white)
        .font(.system(size: 18, weight: .medium))
      Spacer()
    }
  }
  
  
  
  // MARK: - Function
  // MARK: Private
  private func updateStatus(value: DragGesture.Value, proxy: GeometryProxy) {
    guard startX == nil else { return }
    
    let delta = value.startLocation.x - (proxy.size.width - length) * ratio
    startX = (length < value.startLocation.x && 0 < delta) ? delta : value.startLocation.x
  }
  
  private func update(value: DragGesture.Value, proxy: GeometryProxy) {
    guard let x = startX else { return }
    startX = min(length, max(0, x))
    
    var point = value.location.x - x
    let delta = proxy.size.width - length
    
    // Check the boundary
    if point < 0 {
      startX = value.location.x
      point = 0
      
    } else if delta < point {
      startX = value.location.x - delta
      point = delta
    }
    
    // Ratio
    var ratio = point / delta
    
    
    // Step
    if step != 1 {
      let unit = CGFloat(step) / CGFloat(bounds.upperBound)
      
      let remainder = ratio.remainder(dividingBy: unit)
      if remainder != 0 {
        ratio = ratio - CGFloat(remainder)
      }
    }
    
    self.ratio = ratio
    self.value = V(bounds.upperBound) * V(ratio)
    
  }
}

#Preview {
  
  ZStack {
    Color.black
    VolumeSlider(
      value: .constant(0.5),
      in: 0.0...1.0,
      step: 0.1,
      textColor: Color.white
    )
  }
}
