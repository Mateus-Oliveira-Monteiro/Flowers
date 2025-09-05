class PlantInfo {
  final String nome;
  final String descricao;
  final String exposicaoSol;
  final String frequenciaRega;
  final String tipoSolo;
  final String dificuldadeCultivo;
  final String cuidadosEspeciais;

  PlantInfo({
    required this.nome,
    required this.descricao,
    required this.exposicaoSol,
    required this.frequenciaRega,
    required this.tipoSolo,
    required this.dificuldadeCultivo,
    required this.cuidadosEspeciais,
  });

  factory PlantInfo.fromJson(Map<String, dynamic> json) {
    return PlantInfo(
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      exposicaoSol: json['exposicaoSol'] ?? '',
      frequenciaRega: json['frequenciaRega'] ?? '',
      tipoSolo: json['tipoSolo'] ?? '',
      dificuldadeCultivo: json['dificuldadeCultivo'] ?? '',
      cuidadosEspeciais: json['cuidadosEspeciais'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'descricao': descricao,
      'exposicaoSol': exposicaoSol,
      'frequenciaRega': frequenciaRega,
      'tipoSolo': tipoSolo,
      'dificuldadeCultivo': dificuldadeCultivo,
      'cuidadosEspeciais': cuidadosEspeciais,
    };
  }

  @override
  String toString() {
    return 'PlantInfo(nome: $nome, descricao: $descricao, exposicaoSol: $exposicaoSol, frequenciaRega: $frequenciaRega, tipoSolo: $tipoSolo, dificuldadeCultivo: $dificuldadeCultivo, cuidadosEspeciais: $cuidadosEspeciais)';
  }
}
