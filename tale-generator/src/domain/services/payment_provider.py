"""Payment provider interface and mock implementation."""

import logging
import random
import time
from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime
from typing import Optional
from decimal import Decimal

logger = logging.getLogger("tale_generator.payment")


@dataclass
class PaymentRequest:
    """Payment request information."""
    amount: Decimal
    currency: str
    payment_method: str
    user_id: str
    plan_tier: str
    billing_cycle: str
    metadata: Optional[dict] = None


@dataclass
class PaymentResponse:
    """Payment processing response."""
    success: bool
    reference: str
    timestamp: datetime
    amount: Decimal
    currency: str
    error_code: Optional[str] = None
    error_message: Optional[str] = None


class PaymentProvider(ABC):
    """Abstract base class for payment providers."""
    
    @abstractmethod
    def process_payment(self, request: PaymentRequest) -> PaymentResponse:
        """
        Process a payment transaction.
        
        Args:
            request: Payment request details
            
        Returns:
            PaymentResponse with transaction result
        """
        pass
    
    @abstractmethod
    def validate_payment_method(self, payment_method: str) -> bool:
        """
        Validate if payment method is acceptable.
        
        Args:
            payment_method: Payment method identifier
            
        Returns:
            True if valid, False otherwise
        """
        pass
    
    @abstractmethod
    def get_provider_name(self) -> str:
        """
        Get the provider identifier.
        
        Returns:
            Provider name string
        """
        pass


class MockPaymentProvider(PaymentProvider):
    """
    Mock payment provider for development and testing.
    
    Simulates payment processing without actual financial transactions.
    Supports configurable success/failure scenarios for testing.
    """
    
    # Simulated failure scenarios
    FAILURE_SCENARIOS = {
        'mock_card_declined': ('CARD_DECLINED', 'Insufficient funds'),
        'mock_card_expired': ('CARD_EXPIRED', 'Payment method has expired'),
        'mock_network_error': ('NETWORK_ERROR', 'Network connection timeout'),
        'mock_fraud_detected': ('FRAUD_DETECTED', 'Transaction flagged for fraud prevention'),
    }
    
    def __init__(self, success_rate: float = 1.0, processing_delay_ms: int = 1500):
        """
        Initialize mock payment provider.
        
        Args:
            success_rate: Probability of successful transactions (0.0 to 1.0)
            processing_delay_ms: Simulated processing delay in milliseconds
        """
        self.success_rate = success_rate
        self.processing_delay_ms = processing_delay_ms
        logger.info(
            f"Mock payment provider initialized "
            f"(success_rate={success_rate}, delay={processing_delay_ms}ms)"
        )
    
    def process_payment(self, request: PaymentRequest) -> PaymentResponse:
        """
        Simulate payment processing.
        
        Args:
            request: Payment request details
            
        Returns:
            PaymentResponse with simulated result
        """
        logger.info(
            f"Processing mock payment: user_id={request.user_id}, "
            f"amount={request.amount} {request.currency}, "
            f"method={request.payment_method}"
        )
        
        # Simulate processing delay
        time.sleep(self.processing_delay_ms / 1000.0)
        
        # Check for simulated failure scenarios
        if request.payment_method in self.FAILURE_SCENARIOS:
            error_code, error_message = self.FAILURE_SCENARIOS[request.payment_method]
            logger.warning(
                f"Mock payment failed: {error_code} - {error_message}"
            )
            return PaymentResponse(
                success=False,
                reference=self._generate_reference(),
                timestamp=datetime.now(),
                amount=request.amount,
                currency=request.currency,
                error_code=error_code,
                error_message=error_message
            )
        
        # Random failure based on success_rate
        if random.random() > self.success_rate:
            logger.warning("Mock payment randomly failed")
            return PaymentResponse(
                success=False,
                reference=self._generate_reference(),
                timestamp=datetime.now(),
                amount=request.amount,
                currency=request.currency,
                error_code='RANDOM_FAILURE',
                error_message='Simulated random failure for testing'
            )
        
        # Success scenario
        reference = self._generate_reference()
        logger.info(f"Mock payment succeeded: reference={reference}")
        return PaymentResponse(
            success=True,
            reference=reference,
            timestamp=datetime.now(),
            amount=request.amount,
            currency=request.currency
        )
    
    def validate_payment_method(self, payment_method: str) -> bool:
        """
        Validate payment method.
        
        All payment methods are valid for mock provider.
        
        Args:
            payment_method: Payment method identifier
            
        Returns:
            Always True for mock provider
        """
        return True
    
    def get_provider_name(self) -> str:
        """
        Get provider name.
        
        Returns:
            "mock"
        """
        return "mock"
    
    def _generate_reference(self) -> str:
        """
        Generate a mock transaction reference.
        
        Returns:
            Mock reference in format MOCK-XXXXXXXXXXXX
        """
        random_digits = ''.join([str(random.randint(0, 9)) for _ in range(12)])
        return f"MOCK-{random_digits}"
