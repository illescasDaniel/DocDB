//
//  DocDB+Combine.swift
//  
//
//  Created by Daniel Illescas Romero on 07/06/2020.
//

#if canImport(Combine)
import enum Combine.Subscribers
import protocol Combine.Subscriber
import protocol Combine.Subscription
import protocol Combine.Publisher
#endif

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
internal class QuerySubscription<S: Subscriber>: Subscription where S.Input == DocDBDictionary, S.Failure == Error {

	private let queryIterator: QueryIterator
	private var subscriber: S?
	private var count = 0
	
	init(queryIterator: QueryIterator, subscriber: S) {
		self.queryIterator = queryIterator
		self.subscriber = subscriber
	}
	
	func request(_ demand: Subscribers.Demand) {
		sendRequest()
	}
	
	func cancel() {
		subscriber = nil
	}
	
	private func sendRequest() {
		guard let subscriber = subscriber else { return }
		guard let nextValue = self.queryIterator.next() else {
			subscriber.receive(completion: .finished)
			return
		}
		count += 1
		let demand = subscriber.receive(nextValue)
		let maxDemand = demand.max ?? .max
		
		if maxDemand < count {
			sendRequest()
		}
	}
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
internal class QueryPublisher: Publisher {
	
	typealias Output = DocDBDictionary
	typealias Failure = Error
	
	private let queryIterator: QueryIterator
	
	init(queryIterator: QueryIterator) {
		self.queryIterator = queryIterator
	}
	
	func receive<S: Subscriber>(subscriber: S) where QueryPublisher.Failure == S.Failure, QueryPublisher.Output == S.Input {
		let subscription = QuerySubscription(queryIterator: queryIterator, subscriber: subscriber)
		subscriber.receive(subscription: subscription)
	}
}
