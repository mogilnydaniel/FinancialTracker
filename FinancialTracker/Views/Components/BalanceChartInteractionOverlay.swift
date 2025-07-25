import SwiftUI
import Charts

struct BalanceChartInteractionOverlay: View {
    let proxy: ChartProxy
    @Binding var chartData: [BalanceChartDataPoint]
    @Binding var selectedDataPoint: BalanceChartDataPoint?
    @Binding var dragLocation: CGPoint?
    @Binding var showDetailPopup: Bool
    @Binding var longPressActivated: Bool
    let chartHorizontalPadding: CGFloat
    let clearChartSelection: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle().fill(.clear).contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !longPressActivated {
                                updateSelection(at: value.location)
                            }
                        }
                        .onEnded { _ in
                            if !longPressActivated {
                                clearChartSelection()
                                dragLocation = nil
                            }
                        }
                        .simultaneously(with:
                            LongPressGesture(minimumDuration: 0.5)
                                .onEnded { _ in
                                    if selectedDataPoint != nil {
                                        longPressActivated = true
                                        showDetailPopup = true
                                        dragLocation = nil
                                    }
                                }
                        )
                )
                .overlay(alignment: .top) {
                    if let selectedPoint = selectedDataPoint, let dragLocation = self.dragLocation {
                        let popoverXPosition = calculatePopoverPosition(
                            dragLocation: dragLocation,
                            chartWidth: geometry.size.width
                        )
                        
                        Rectangle()
                            .fill(Color.secondary)
                            .frame(width: 1, height: 150)
                            .position(x: dragLocation.x, y: 75)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedPoint.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(abs(selectedPoint.amount).rubleFormatted)
                                .font(.headline.bold())
                                .foregroundColor(selectedPoint.type == .income ? .green : .orange)
                        }
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 4)
                        .position(x: popoverXPosition, y: 30)
                        .transition(.opacity.animation(.easeInOut(duration: 0.1)))
                    }
                }
        }
    }
    
    private func calculatePopoverPosition(dragLocation: CGPoint, chartWidth: CGFloat) -> CGFloat {
        let chartContentWidth = chartWidth - (chartHorizontalPadding * 2)
        let selectionX = dragLocation.x - chartHorizontalPadding
        if selectionX < chartContentWidth / 3 {
            return dragLocation.x + 55
        } else if selectionX > chartContentWidth * 2 / 3 {
            return dragLocation.x - 55
        } else {
            return dragLocation.x
        }
    }
    
    private func updateSelection(at location: CGPoint) {
        let xPosition = location.x - chartHorizontalPadding
        guard let date: Date = proxy.value(atX: xPosition) else { return }
        var minDistance: TimeInterval = .greatestFiniteMagnitude
        var closestDataPoint: BalanceChartDataPoint? = nil
        for dataPoint in chartData {
            let distance = abs(dataPoint.date.timeIntervalSince(date))
            if distance < minDistance {
                minDistance = distance
                closestDataPoint = dataPoint
            }
        }
        if let closestDataPoint {
            selectedDataPoint = closestDataPoint
            if let xPos = proxy.position(forX: closestDataPoint.date) {
                self.dragLocation = CGPoint(x: xPos + chartHorizontalPadding, y: 0)
            }
        }
    }
} 


