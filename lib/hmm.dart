import 'dart:io';
import 'dart:math' as Math;

List<double> applyHammingWindow(List<double> frame) {
  File file = File("hmm/Hamming_window.txt");
  var fileContent = file.readAsStringSync();

  List hammingCoefficients = fileContent.split(' ');

  for (int i = 0; i < 320; i++) {
    frame[i] = frame[i] * hammingCoefficients[i];
  }

  return frame;
}

List<double> applyRaisedSineWindow(List<double> frame) {
  for (int i = 0; i < 12; i++) {
    double aux = Math.sin((Math.pi * (i + 1)) / 12.0);
    frame[i] = frame[i] * (1.0 + 6.0 * aux);
  }

  return frame;
}

double compute_correlation(List<double> frame, int lag) {
  double correlation = 0.0;
  for (int index = lag; index < frame.length; index++) {
    correlation += frame[index] * frame[index - lag];
  }
  return correlation;
}

List<double> compute_levensionDurbins(List<double> correlation_coefficients) {
  double e = correlation_coefficients[0];
  double k;
  List<double> aux = [];
  List<double> lpc_coefficients = [];

  for (int i = 1; i <= 12; i++) {
    k = correlation_coefficients[i];
    for (int j = 1; j < i; j++) {
      k -= lpc_coefficients[j - 1] * correlation_coefficients[i - j];
    }
    k /= e;

    for (int j = 1; j < i; j++) {
      aux[j - 1] = lpc_coefficients[j - 1] - k * lpc_coefficients[i - j - 1];
    }
    aux.add(k);

    lpc_coefficients = aux;
    e = (1 - k * k) * e;
  }

  return lpc_coefficients;
}

List<double> compute_cepstral_coefficients(List<double> lpc_coefficients) {
  List<double> cepstral_coefficients = [];

  for (int i = 0; i < 12; i++) {
    cepstral_coefficients.add(lpc_coefficients[i]);
    for (int j = 0; j < i; j++) {
      cepstral_coefficients[i] += ((j + 1) / (i + 1)) *
          cepstral_coefficients[j] *
          lpc_coefficients[i - j - 1];
    }
  }

  return cepstral_coefficients;
}

List<int> get_observation_sequence(List<double> amplitudes) {
  List<int> seq = [];

  for (int i = 0; i + 320 < amplitudes.length; i += 320) {
    List<double> frame = [];
    for (int j = i; j < i + 320; j++) {
      frame.add(amplitudes[j]);
    }

    frame = applyHammingWindow(frame);

    List<double> correlation_coefficients = [];
    for (int k = 0; k <= 12; k++) {
      correlation_coefficients.add(compute_correlation(frame, k));
    }

    List<double> lpc_coefficients = [];
    lpc_coefficients = compute_levensionDurbins(correlation_coefficients);

    List<double> cepstral_coefficients = [];
    cepstral_coefficients = compute_cepstral_coefficients(lpc_coefficients);

    cepstral_coefficients = applyRaisedSineWindow(cepstral_coefficients);

    File file = File("hmm/codebook.csv");
    var fileContent = file.readAsStringSync();

    List codeBook = fileContent.split(',');

    int obs = -1;
    double mndis = 0;
    for (int k = 0; k < 32; k++) {
      double dis = 0;
      for (int j = 0; j < 12; j++) {
        int ind = j + k * 12;
        dis += (codeBook[ind] - cepstral_coefficients[j]) *
            (codeBook[ind] - cepstral_coefficients[j]);
      }

      if (obs == -1 || mndis > dis) {
        obs = k;
        mndis = dis;
      }
    }

    seq.add(obs);
  }

  return seq;
}

double forward_procedure(List pi, List a, List b, int n, int m, List o, int T) {
  var alpha =
      List.generate(T, (i) => List.generate(n, (j) => 0.0), growable: false);

  for (int j = 0; j < n; j++) {
    alpha[0][j] = pi[j] * b[0][o[0] - 1];
  }

  for (int i = 1; i < T; i++) {
    for (int j = 0; j < n; j++) {
      alpha[i][j] = 0.0;
      for (int k = 0; k < n; k++) {
        alpha[i][j] += alpha[i - 1][k] * a[k][j];
      }
      alpha[i][j] *= b[j][o[i] - 1];
    }
  }

  double prob = 0.0;
  for (int i = 0; i < n; i++) {
    prob += alpha[T - 1][i];
  }

  //print alpha
  //for(int i=0; i<T; i++)
  //{
  //	for(int j=0; j<n; j++)
  //	{
  //		cout<<alpha[i][j]<<" ";
  //	}
  //	cout<<endl;
  //}
  return prob;
}

String _test_hmm(String filePath) {
  File file = File(filePath);
  var fileContent = file.readAsStringSync();

  List<double> amplitudes =
      fileContent.split('\n').map((e) => double.parse(e)).toList();

  List<int> observation_sequence = get_observation_sequence(amplitudes);
  int T = observation_sequence.length;

  List words = [
    'hello',
    'hi',
    'hey',
    'thank you',
    'thanks',
    'cost',
    'price',
    'water',
    'drink',
    'food',
    'eat',
    'tourist place',
    'visit place',
    'direction',
    'way',
    'ride'
  ];

  double mxprob = 0.0;
  int ans = 0;

  for (int i = 0; i < words.length; i++) {
    File piFile = File("hmm/models/avg_pi_" + words[i] + ".txt");
    var piFileContent = piFile.readAsStringSync();
    List pi = piFileContent.split(' ');

    File aFile = File("hmm/models/avg_a_" + words[i] + ".txt");
    var aFileContent = aFile.readAsLinesSync();
    List<List<double>> a = [];
    for (int j = 0; j < aFileContent.length; j++) {
      a.add(aFileContent[j].split(' ').map((e) => double.parse(e)).toList());
    }
    int n = a.length;

    File bFile = File("hmm/models/avg_b_" + words[i] + ".txt");
    var bFileContent = bFile.readAsLinesSync();
    List<List<double>> b = [];
    for (int j = 0; j < aFileContent.length; j++) {
      b.add(bFileContent[j].split(' ').map((e) => double.parse(e)).toList());
    }
    int m = b[0].length;

    double prob = forward_procedure(pi, a, b, n, m, observation_sequence, T);

    if (prob > mxprob) {
      mxprob = prob;
      ans = i;
    }
  }

  return words[ans];
}

//////////////////////////////////////////////////////////////////////////////////////
///                 TRAINING                          ///

List<List<double>> forward_procedure1(
    List pi, List a, List b, int n, int m, List o, int T) {
  var alpha =
      List.generate(T, (i) => List.generate(n, (j) => 0.0), growable: false);

  for (int j = 0; j < n; j++) {
    alpha[0][j] = pi[j] * b[0][o[0] - 1];
  }

  for (int i = 1; i < T; i++) {
    for (int j = 0; j < n; j++) {
      alpha[i][j] = 0.0;
      for (int k = 0; k < n; k++) {
        alpha[i][j] += alpha[i - 1][k] * a[k][j];
      }
      alpha[i][j] *= b[j][o[i] - 1];
    }
  }

  double prob = 0.0;
  for (int i = 0; i < n; i++) {
    prob += alpha[T - 1][i];
  }

  //print alpha
  //for(int i=0; i<T; i++)
  //{
  //	for(int j=0; j<n; j++)
  //	{
  //		cout<<alpha[i][j]<<" ";
  //	}
  //	cout<<endl;
  //}
  return alpha;
}

List<List<double>> backward_procedure(
    List pi, List a, List b, int n, int m, List o, int T) {
  var beta =
      List.generate(T, (i) => List.generate(n, (j) => 0.0), growable: false);
  for (int j = 0; j < n; j++) {
    beta[T - 1][j] = 1.0;
  }

  for (int i = T - 2; i >= 0; i--) {
    for (int j = 0; j < n; j++) {
      beta[i][j] = 0.0;

      for (int k = 0; k < n; k++) {
        beta[i][j] += a[j][k] * b[k][o[i + 1] - 1] * beta[i + 1][k];
      }
    }
  }

  //print beta
  //for(int i=0; i<T; i++)
  //{
  //	for(int j=0; j<n; j++)
  //	{
  //		cout<<beta[i][j]<<" ";
  //	}
  //	cout<<endl;
  //}

  return beta;
}

void get_frames(List<double> processedData, List<List<double>> frames) {
  double mx = 0.0; //store maximum absolute value
  int mx_index = 320;

  for (int i = 320; i < processedData.length - 320; i++) {
    if (processedData[i] < 0.0) {
      if (mx < processedData[i] * -1.0) {
        mx = (processedData[i] * -1.0);
        mx_index = i;
      }
    } else {
      if (mx < processedData[i]) {
        mx = processedData[i];
        mx_index = i;
      }
    }
  }

  for (int i = 0; i < 5; i++) {
    int starting_index = mx_index - 80 * (i);

    for (int j = 0; j < 320; j++) {
      frames[i][j] = processedData[starting_index + j];
    }
  }
}

List<List<double>> get_gamma(List alpha, List beta, int n, int T) {
  var gamma =
      List.generate(T, (i) => List.generate(n, (j) => 0.0), growable: false);
  for (int i = 0; i < T; i++) {
    double sum = 0.0;
    for (int j = 0; j < n; j++) {
      sum += alpha[i][j] * beta[i][j];
    }

    for (int j = 0; j < n; j++) {
      gamma[i][j] = (alpha[i][j] * beta[i][j]) / sum;
    }
  }

  return gamma;
}

List<List<List<double>>> get_ita(
    List alpha, List beta, List a, List b, List o, int n, int m, int T) {
  var ita = List.generate(
      T, (i) => List.generate(n, (j) => List.generate(n, (k) => 0.0)),
      growable: false);
  for (int i = 0; i < T - 1; i++) {
    double sum = 0.0;
    for (int j = 0; j < n; j++) {
      for (int k = 0; k < n; k++) {
        ita[i][j][k] =
            alpha[i][j] * a[j][k] * b[k][o[i + 1] - 1] * beta[i + 1][k];
        sum += ita[i][j][k];
      }
    }

    for (int j = 0; j < n; j++) {
      for (int k = 0; k < n; k++) {
        ita[i][j][k] /= sum;
      }
    }
  }

  return ita;
}

List<int> viterbi(List pi, List a, List b, int n, int m, List o, int T) {
  var gamma =
      List.generate(T, (i) => List.generate(n, (j) => 0), growable: false);
  var delta =
      List.generate(T, (i) => List.generate(n, (j) => 0.0), growable: false);
  var optimal_state_sequence = List.generate(T, (i) => 0);

  for (int j = 0; j < n; j++) {
    delta[0][j] = pi[j] * b[j][o[0] - 1];
    gamma[0][j] = -1;
  }

  for (int i = 1; i < T; i++) {
    for (int j = 0; j < n; j++) {
      delta[i][j] = 0.0;
      gamma[i][j] = -1;

      for (int k = 0; k < n; k++) {
        //cout<<delta[i-1][k]<<" * "<<a[k][j]<<endl;
        if (delta[i - 1][k] * a[k][j] > delta[i][j]) {
          gamma[i][j] = k;
          delta[i][j] = delta[i - 1][k] * a[k][j];
        }
      }
      delta[i][j] *= b[j][o[i] - 1];
    }
  }

  double max_state_prob = 0.0;
  int q = -1;

  for (int j = 0; j < n; j++) {
    if (max_state_prob < delta[T - 1][j]) {
      max_state_prob = delta[T - 1][j];
      q = j;
    }
  }

  optimal_state_sequence[T - 1] = q;
  for (int i = T - 2; i >= 0; i--) {
    //cout<<optimal_state_sequence[i+1]<<endl;
    optimal_state_sequence[i] = gamma[i + 1][optimal_state_sequence[i + 1]];
  }

  //print optimal state sequence
  //cout<<"P* = "<<max_state_prob<<endl;
  //for(int i=0; i<T; i++)
  //{
  //	cout<<optimal_state_sequence[i]<<" ";
  //}
  //cout<<endl;

  return optimal_state_sequence;
}

List<double> update_pi(List gamma, int n, List<double> pi) {
  for (int j = 0; j < n; j++) {
    pi[j] = gamma[0][j];
  }

  return pi;
}

List<List<double>> update_state_transition_matrix(
    List ita, List gamma, int n, int T, List<List<double>> a) {
  //cout<<"new state transition matrix is : "<<endl;
  for (int j = 0; j < n; j++) {
    for (int k = 0; k < n; k++) {
      double num = 0.0;
      double den = 0.0;

      for (int i = 0; i < T - 1; i++) {
        num += ita[i][j][k];
        den += gamma[i][j];
      }

      if (den == 0.0) {
        a[j][k] = 0.0;
      } else {
        a[j][k] = num / den;
      }
      //cout<<num/den<<" ";
    }
    //cout<<endl;
  }

  return a;
}

List<List<double>> update_beta(
    List gamma, List o, int n, int m, int T, List<List<double>> b) {
  for (int j = 0; j < n; j++) {
    for (int k = 0; k < m; k++) {
      double num = 0.0;
      double den = 0.0;

      for (int i = 0; i < T; i++) {
        den += gamma[i][j];
        if (o[i] - 1 == k) {
          num += gamma[i][j];
        }
      }

      if (den == 0.0) {
        b[j][k] = 0.0;
      } else {
        b[j][k] = num / den;
      }
    }
  }

  return b;
}

void train_HMM(String filePath, String label) {
  File file = File(filePath);
  var fileContent = file.readAsStringSync();

  List<double> amplitudes =
      fileContent.split('\n').map((e) => double.parse(e)).toList();

  List<int> observation_sequence = get_observation_sequence(amplitudes);
  int T = observation_sequence.length;

  File piFile = File("hmm/models/avg_pi_" + label + ".txt");
  var piFileContent = piFile.readAsStringSync();
  List<double> pi =
      piFileContent.split(' ').map((e) => double.parse(e)).toList();

  File aFile = File("hmm/models/avg_a_" + label + ".txt");
  var aFileContent = aFile.readAsLinesSync();
  List<List<double>> a = [];
  for (int j = 0; j < aFileContent.length; j++) {
    a.add(aFileContent[j].split(' ').map((e) => double.parse(e)).toList());
  }
  int n = a.length;

  File bFile = File("hmm/models/avg_b_" + label + ".txt");
  var bFileContent = bFile.readAsLinesSync();
  List<List<double>> b = [];
  for (int j = 0; j < aFileContent.length; j++) {
    b.add(bFileContent[j].split(' ').map((e) => double.parse(e)).toList());
  }
  int m = b[0].length;

  List<List<double>> alpha =
      forward_procedure1(pi, a, b, n, m, observation_sequence, T);
  List<List<double>> beta =
      backward_procedure(pi, a, b, n, m, observation_sequence, T);
  List<List<double>> gamma = get_gamma(alpha, beta, n, T);
  List<List<List<double>>> ita =
      get_ita(alpha, beta, a, b, observation_sequence, n, m, T);

  List<int> optimal_state_sequence =
      viterbi(pi, a, b, n, m, observation_sequence, T);

  pi = update_pi(gamma, n, pi);
  a = update_state_transition_matrix(ita, gamma, n, T, a);
  b = update_beta(gamma, observation_sequence, n, m, T, b);
}

class SpeechToText {
  late List codeBook;
  late String label;

  SpeechToText(String l) {
    String label = l;
    File file = File("hmm/codebook.csv");
    var fileContent = file.readAsStringSync();
    List codeBook = fileContent.split(',');
  }

  listen() {
    _test_hmm('hmm/audio.txt');
  }

  liveTrain() {
    train_HMM('hmm/audio.txt', label);
  }
}
