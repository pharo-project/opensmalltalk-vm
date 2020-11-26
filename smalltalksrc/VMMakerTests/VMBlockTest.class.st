Class {
	#name : #VMBlockTest,
	#superclass : #VMInterpreterTests,
	#pools : [
		'VMObjectIndices',
		'VMSqueakClassIndices'
	],
	#category : #'VMMakerTests-InterpreterTests'
}

{ #category : #supports }
VMBlockTest >> anEmptyMethod [
]

{ #category : #helpers }
VMBlockTest >> installBlockClosureClass [
		| aClass |
	aClass := self
		newClassInOldSpaceWithSlots: 0
		instSpec: BlockClosure instSpec.
	memory setHashBitsOf: aClass to: ClassBlockClosureCompactIndex.
	memory
		storePointer: ClassBlockClosureCompactIndex
		ofObject: memory classTableFirstPage
		withValue: aClass
]

{ #category : #helpers }
VMBlockTest >> installBlockClosureClassInSplOnly [
		| aClass |
	aClass := self
		newClassInOldSpaceWithSlots: 0
		instSpec: BlockClosure instSpec.
	memory setHashBitsOf: aClass to: ClassBlockClosureCompactIndex.
	memory splObj: ClassBlockClosure put: aClass
]

{ #category : #supports }
VMBlockTest >> methodReturningABlock [
	
	^ []
	
]

{ #category : #tests }
VMBlockTest >> testBlockClosureClassIsOnlyInSpecialObjectArrayShouldStillInstantiate [

	| methodOop methodHeader previousMethodOop |
	methodOop := self createMethodOopFromPharoMethod:
		             self class >> #methodReturningABlock.

	previousMethodOop := self createMethodOopFromPharoMethod:
		                     self class >> #anEmptyMethod.
	"To force the use of the specialObjectArray"	
	ClassBlockClosureCompactIndex := 0.
	self installBlockClosureClassInSplOnly.
	"We want to avoid baseFrameReturn (base frame initialisation)"
	stackBuilder addNewFrame method: previousMethodOop.
	stackBuilder addNewFrame
		method: methodOop;
		receiver: memory trueObject.
	stackBuilder buildStack.
	methodHeader := memory methodHeaderOf: methodOop.

	interpreter instructionPointer:
		(interpreter initialIPForHeader: methodHeader method: methodOop) - 1.
	interpreter interpretWhile: [ interpreter method = methodOop ].

	self
		assert: (memory fetchClassOf: interpreter stackTop)
		equals: (memory classAtIndex: ClassBlockClosureCompactIndex)
]

{ #category : #testing }
VMBlockTest >> testCreatingABlockClosureShouldHaveOuterContextObject [

	| methodOop previousMethodOop |
	methodOop := self createMethodOopFromPharoMethod:
		             self class >> #methodReturningABlock.

	previousMethodOop := self createMethodOopFromPharoMethod:
		                     self class >> #anEmptyMethod.

	self installBlockClosureClass.
	"We want to avoid baseFrameReturn (base frame initialisation)"
	stackBuilder addNewFrame method: previousMethodOop.
	stackBuilder addNewFrame
		method: methodOop;
		receiver: memory trueObject.
	stackBuilder buildStack.
	
	interpreter instructionPointer: (methodBuilder bytecodeAt: 0 forMethod: methodOop).
	interpreter interpretWhile: [ interpreter method = methodOop ].

	"Currently fails because the stack frame is not overriden.
	So the interpreter considers it's still married even thought the stack frame is already dead"
	self
		assert: (interpreter isWidowedContext: (memory outerContextOf: interpreter stackTop))

]

{ #category : #testing }
VMBlockTest >> testPushClosureBytecodePushesClosure [

	| methodOop previousMethodOop |
	methodOop := self createMethodOopFromPharoMethod:
		             self class >> #methodReturningABlock.

	previousMethodOop := self createMethodOopFromPharoMethod:
		                     self class >> #anEmptyMethod.

	self installBlockClosureClass.
	"We want to avoid baseFrameReturn (base frame initialisation)"
	stackBuilder addNewFrame method: previousMethodOop.
	stackBuilder addNewFrame
		method: methodOop;
		receiver: memory trueObject.
	stackBuilder buildStack.
	
	interpreter instructionPointer: (methodBuilder bytecodeAt: 0 forMethod: methodOop).
	interpreter interpretWhile: [ interpreter method = methodOop ].

	self
		assert: (memory fetchClassOf: interpreter stackTop)
		equals: (memory classAtIndex: ClassBlockClosureCompactIndex)
]