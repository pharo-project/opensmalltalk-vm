Class {
	#name : #VMPrimitiveCallAbstractTest,
	#superclass : #VMSimpleStackBasedCogitAbstractTest,
	#instVars : [
		'baseMethodIP',
		'baseFrame',
		'baseMethod'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #helpers }
VMPrimitiveCallAbstractTest >> createBaseFrame [

	"Create the root context with a valid method"
	"Let's create a method with enough size. It should have at least a literal (4 or 8 bytes depending the word size) and some bytecodes, so we can put the IP inside the method"
	| ctx page |
	
	baseMethod := methodBuilder newMethod
		literals: { memory nilObject. memory nilObject }; 
		buildMethod.
	
	baseMethodIP := memory lastPointerOf: baseMethod.
	
	"The context has 5 (in 32 bits) or 9 (in 64 bits) as initial IP, as method has at least one literal"
	ctx := self newSmallContextReceiver: memory nilObject method: baseMethod arguments: #() temporaries: #() ip: baseMethodIP + 1.

	"The base context has a trampoline as the savedIP so it can return to a context that is in the heap"
	cogit ceBaseFrameReturnTrampoline: 16rAABBCCDD.	
	
	page := interpreter makeBaseFrameFor: ctx.
	interpreter setStackPointersFromPage: page.
	interpreter setStackPageAndLimit: page.
	interpreter instructionPointer: interpreter popStack.
	
	"keeping track of the base frame."
	baseFrame := interpreter framePointer. 

]

{ #category : #helpers }
VMPrimitiveCallAbstractTest >> findMethod: aSelector [

	^ self class lookupSelector: aSelector
]

{ #category : #helpers }
VMPrimitiveCallAbstractTest >> jitMethod: aPharoCompiledMethod [ 

	^ self jitMethod: aPharoCompiledMethod selector: memory nilObject
]

{ #category : #helpers }
VMPrimitiveCallAbstractTest >> jitMethod: aPharoCompiledMethod selector: aSelectorOop [

	| methodOop v3Method |
	
	"We are using V3 bytecode, so we need to recompile the method"
	v3Method := self class compiler
							encoderClass: EncoderForV3PlusClosures;
							options: #(-optionFullBlockClosure);
							compile: aPharoCompiledMethod sourceCode.
	
	methodOop := methodBuilder fillFromPharoMethod: v3Method; buildMethod.

	^ cogit cog: methodOop selector: aSelectorOop
]

{ #category : #'methods under test' }
VMPrimitiveCallAbstractTest >> methodThatCallNamedPrimitive: anArg [

	"This method is used to test the invocation of a primitive.
	The primitive to invoke is later changed in the primitive table of the interpreter used in the test"
	<primitive: 'primitiveThatDoNothingWithOneArgument'>
	
	^ 84
]

{ #category : #'methods under test' }
VMPrimitiveCallAbstractTest >> methodThatCallNamedPrimitiveCounting: anArg [

	"This method is used to test the invocation of a primitive.
	The primitive to invoke is later changed in the primitive table of the interpreter used in the test"
	<primitive: 'primitiveFailCounting'>
	
	^ 84
]

{ #category : #'methods under test' }
VMPrimitiveCallAbstractTest >> methodThatCallPrimitive159 [

	<primitive: 159>

	^ 42 
]

{ #category : #'methods under test' }
VMPrimitiveCallAbstractTest >> methodThatCallPrimitive1: anArg [

	"This method is used to test the invocation of a primitive.
	The primitive to invoke is later changed in the primitive table of the interpreter used in the test"
	<primitive: 1>
	
	^ 42
]

{ #category : #'methods under test' }
VMPrimitiveCallAbstractTest >> methodToCompile1 [

	^ 42 bitInvert
]

{ #category : #tests }
VMPrimitiveCallAbstractTest >> setUp [

	| primitiveAccessorDepthTable |
	
	super setUp.
	self setUpCogMethodEntry.

	"Initializing the accessor depth table with a value for the first primitive"
	primitiveAccessorDepthTable := Array new: interpreter primitiveTable size.
	
	1 to: interpreter primitiveTable size 
		do: [ :i | primitiveAccessorDepthTable at: i put: -1 ].	 

	interpreter primitiveAccessorDepthTable: primitiveAccessorDepthTable.
	
	cogit 	lastNInstructions: OrderedCollection new.
	
	cogit guardPageSize: cogit class guardPageSize.
]