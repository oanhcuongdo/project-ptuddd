import '../models/fund_transaction_model.dart';

abstract class IFundTransactionRepository {
  Future<List<FundTransactionModel>> getTransactions();
  Future<int> recordTransaction(FundTransactionModel tx);
  Future<double> getTotalIncome();
  Future<double> getTotalExpense();
  Future<double> getBalance();
  Future<List<FundTransactionModel>> filterTransactions({
    TransactionType? type,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
  });
}
